/*
    Multisignature Wallet with setcode
    Copyright (C) 2022 Ever Surf

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
pragma ever-solidity ^0.64.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import "../base/Base.sol";
import "./IMultiSignatureWallet.sol";
import "./ISetCodeSupport.sol";

/// @title Multi Signature Wallet 3.0 Implementation (can deploy other contracts, can choose transaction expiration time)
/// @author deplant (https://github.com/deplant)
contract MultiSignatureWallet is IMultiSignatureWallet, ISetCodeSupport, Base {

	// ****************************************************************	
	// Constants
	// ****************************************************************	
    uint8   constant MAX_QUEUED_REQUESTS = 5;
    uint64  constant EXPIRATION_TIME = 3600; // TODO declare as variable lifetime is 1 hour
    uint8   constant MAX_CUSTODIAN_COUNT = 32;
    uint    constant MAX_CLEANUP_TXNS = 40;

	// ****************************************************************	
	// State Variables
	// ****************************************************************	
    // Public key of custodian who deployed a contract.
    uint256 m_ownerKey;
    // Binary mask with custodian requests (max 32 custodians).
    uint256 m_requestsMask;
    // Dictionary of queued transactions waiting confirmations.
    mapping(uint64 => Transaction) m_transactions;
    // Set of custodians, initiated in constructor, but values can be changed later in code.
    mapping(uint256 => uint8) m_custodians; // pub_key -> custodian_index
    // Read-only custodian count, initiated in constructor.
    uint8 m_custodianCount;
    // Set of update requests.
    mapping (uint64 => UpdateRequest) m_updateRequests;
    // Binary mask for storing update request counts from custodians.
    // Every custodian can submit only one request.
    uint32 m_updateRequestsMask;
    // Number of custodian confirmations for updating code
    uint8 m_requiredVotes;
    // Default number of confirmations needed to execute transaction.
    uint8 m_defaultRequiredConfirmations;

	// ****************************************************************	
	// Exceptions
	// ****************************************************************	
    /*
    Exception codes:
    100 - message sender is not a custodian;
    102 - transaction does not exist;
    103 - operation is already confirmed by this custodian;
    107 - input value is too low;
    108 - wallet should have only one custodian;
    110 - Too many custodians;
    113 - Too many requests for one custodian;
    115 - update request does not exist;
    116 - update request already confirmed by this custodian;
    117 - invalid number of custodians;
    119 - stored code hash and calculated code hash are not equal;
    120 - update request is not confirmed;
    121 - payload size is too big;
    122 - object is expired;
    */

	// ****************************************************************	
	// Constructor
	// ****************************************************************	
	
    /// @dev Contract constructor.
    /// @param owners Array of custodian keys.
    /// @param reqConfirms Default number of confirmations required for executing transaction.
    constructor(uint256[] owners, uint8 reqConfirms) public {
        require(msg.pubkey() == tvm.pubkey(), 100);
        require(owners.length > 0 && owners.length <= MAX_CUSTODIAN_COUNT, 117);
        tvm.accept();
        _initialize(owners, reqConfirms);
    }
	
    /// @dev Internal function called from constructor to initialize custodians.
    function _initialize(uint256[] owners, uint8 reqConfirms) inline private {
        uint8 ownerCount = 0;
        m_ownerKey = owners[0];

        uint256 len = owners.length;
        for (uint256 i = 0; (i < len && ownerCount < MAX_CUSTODIAN_COUNT); i++) {
            uint256 key = owners[i];
            if (!m_custodians.exists(key)) {
                m_custodians[key] = ownerCount++;
            }
        }
        m_defaultRequiredConfirmations = ownerCount <= reqConfirms ? ownerCount : reqConfirms;
        m_requiredVotes = (ownerCount <= 2) ? ownerCount : ((ownerCount * 2 + 1) / 3);
        m_custodianCount = ownerCount;
    }	
	
	// ****************************************************************	
	// External
	// ****************************************************************	
    function sendTransaction(
        address dest,
        uint128 value,
        bool bounce,
        uint8 flags,
        TvmCell payload) override public view onlySingleOwner
    {
        dest.transfer({value: value, bounce: bounce, flag: flags | IGNORE_ERRORS, body: payload});
    }
	
    function sendTransaction(
        address dest,
        uint128 value,
        bool bounce,
        uint8 flags,
        TvmCell payload,
		TvmCell stateInit) override public view onlySingleOwner
    {
        dest.transfer({value: value, bounce: bounce, flag: flags | IGNORE_ERRORS, body: payload, stateInit: stateInit});
    }	

    function submitTransaction(
        address dest,
        uint128 value,
        bool bounce,
        bool allBalance,
        TvmCell payload)
    override public returns (uint64 transId)
    {
        uint8 index = _findCustodian(msg.pubkey());
        _removeExpiredTransactions();
        require(_getMaskValue(m_requestsMask, index) < MAX_QUEUED_REQUESTS, 113);
        tvm.accept();

        (uint8 flags, uint128 realValue) = _getSendFlags(value, allBalance);
        uint8 requiredSigns = m_defaultRequiredConfirmations;

        if (requiredSigns <= 1) {
            dest.transfer(realValue, bounce, flags, payload);
            return 0;
        } else {
            m_requestsMask = _incMaskValue(m_requestsMask, index);
            uint64 trId = _generateId();
            Transaction txn = Transaction(trId, 0/*mask*/, requiredSigns, 0/*signsReceived*/,
                msg.pubkey(), index, dest, realValue, flags, payload, bounce);

            _confirmTransaction(trId, txn, index);
            return trId;
        }
    }

    function confirmTransaction(uint64 transactionId) override public {
        uint8 index = _findCustodian(msg.pubkey());
        _removeExpiredTransactions();
        optional(Transaction) txnOpt = m_transactions.fetch(transactionId);
        require(txnOpt.hasValue(), 102);
        Transaction txn = txnOpt.get();
        require(!_isConfirmed(txn.confirmationsMask, index), 103);
        tvm.accept();
        _confirmTransaction(transactionId, txn, index);
    }

	// ****************************************************************	
	// External (SETCODE)
	// ****************************************************************	
	
    function submitUpdate(uint256 codeHash, uint256[] owners, uint8 reqConfirms) override public 
        returns (uint64 updateId) 
    {
        uint8 index = _findCustodian(msg.pubkey());
        // TODO check reqConfirms
        require(owners.length > 0 && owners.length <= MAX_CUSTODIAN_COUNT, 117);
        _removeExpiredUpdateRequests();
        require(!_isConfirmed(m_updateRequestsMask, index), 113);
        tvm.accept();

        m_updateRequestsMask = _setConfirmed(m_updateRequestsMask, index);
        updateId = _generateId();
        m_updateRequests[updateId] = UpdateRequest(updateId, index, 0/*signs*/, 0/*mask*/, 
            msg.pubkey(), codeHash, owners, reqConfirms);
        _confirmUpdate(updateId, index);
    }

    function confirmUpdate(uint64 updateId) override public {
        uint8 index = _findCustodian(msg.pubkey());
        _removeExpiredUpdateRequests();
        optional(UpdateRequest) requestOpt = m_updateRequests.fetch(updateId);
        require(requestOpt.hasValue(), 115);
        require(!_isConfirmed(requestOpt.get().confirmationsMask, index), 116);
        tvm.accept();
        _confirmUpdate(updateId, index);
    }

    function executeUpdate(uint64 updateId, TvmCell code) override public {
        require(m_custodians.exists(msg.pubkey()), 100);
        _removeExpiredUpdateRequests();
        optional(UpdateRequest) requestOpt = m_updateRequests.fetch(updateId);
        require(requestOpt.hasValue(), 115);
        UpdateRequest request = requestOpt.get();
        require(tvm.hash(code) == request.codeHash, 119);
        require(request.signs >= m_requiredVotes, 120);
        tvm.accept();

        _deleteUpdateRequest(updateId, request.index);

        tvm.setcode(code);
        tvm.setCurrentCode(code);
        onCodeUpgrade(request.custodians, request.reqConfirms);
    }

	// ****************************************************************	
	// Getters
	// ****************************************************************	
	
    function isConfirmed(uint32 mask, uint8 index) override public pure returns (bool confirmed) {
        confirmed = _isConfirmed(mask, index);
    }

    function getParameters() override public view
        returns (uint8 maxQueuedTransactions,
                uint8 maxCustodianCount,
                uint64 expirationTime,
                uint128 minValue,
                uint8 requiredTxnConfirms,
                uint8 requiredUpdConfirms) {

        maxQueuedTransactions = MAX_QUEUED_REQUESTS;
        maxCustodianCount = MAX_CUSTODIAN_COUNT;
        expirationTime = EXPIRATION_TIME;
        minValue = 0;
        requiredTxnConfirms = m_defaultRequiredConfirmations;
        requiredUpdConfirms = m_requiredVotes;
    }

    function getTransaction(uint64 transactionId) override public view
        returns (Transaction trans) {
        optional(Transaction) txnOpt = m_transactions.fetch(transactionId);
        require(txnOpt.hasValue(), 102);
        trans = txnOpt.get();
    }

    function getTransactions() override public view returns (Transaction[] transactions) {
        uint64 bound = _getExpirationBound();
        for ((uint64 id, Transaction txn): m_transactions) {
            // returns only not expired transactions
            if (id > bound) {
                transactions.push(txn);
            }
        }
    }

    function getTransactionIds() override public view returns (uint64[] ids) {
        for ((uint64 trId, ): m_transactions) {
            ids.push(trId);
        }
    }

    function getCustodians() override public view returns (CustodianInfo[] custodians) {
        for ((uint256 key, uint8 index): m_custodians) {
            custodians.push(CustodianInfo(index, key));
        }
    }    

	// ****************************************************************	
	// Getters (SETCODE)
	// ****************************************************************	
	
    function getUpdateRequests() override public view returns (UpdateRequest[] updates) {
        uint64 bound = _getExpirationBound();
        for ((uint64 updateId, UpdateRequest req): m_updateRequests) {
            if (updateId > bound) {
                updates.push(req);
            }
        }
    }	


	// ****************************************************************	
	// Internal
	// ****************************************************************	
	
    /// @dev Confirms transaction by custodian with defined index.
    function _confirmTransaction(
        uint64 transactionId,
        Transaction txn,
        uint8 custodianIndex
    ) inline private {
        if ((txn.signsReceived + 1) >= txn.signsRequired) {
            txn.dest.transfer(txn.value, txn.bounce, txn.sendFlags, txn.payload);
            m_requestsMask = _decMaskValue(m_requestsMask, txn.index);
            delete m_transactions[transactionId];
        } else {
            txn.confirmationsMask = _setConfirmed(txn.confirmationsMask, custodianIndex);
            txn.signsReceived++;
            m_transactions[transactionId] = txn;
        }
    }

    /// @dev Removes expired transactions from storage.
    function _removeExpiredTransactions() inline private {
        uint64 marker = _getExpirationBound();
        if (m_transactions.empty()) return;

        (uint64 trId, Transaction txn) = m_transactions.min().get();
        bool needCleanup = trId <= marker;
        
        if (needCleanup) {
            tvm.accept();
            uint i = 0;
            while (needCleanup && i < MAX_CLEANUP_TXNS) {
                i++;
                // transaction is expired, remove it
                m_requestsMask = _decMaskValue(m_requestsMask, txn.index);
                delete m_transactions[trId];
                optional(uint64, Transaction) nextTxn = m_transactions.next(trId);
                if (nextTxn.hasValue()) {
                    (trId, ) = nextTxn.get();
                    needCleanup = trId <= marker;
                } else {
                    needCleanup = false;
                }
            }
            tvm.commit();
        }
    }
	
    /// @dev Internal function for update confirmation.
    function _confirmUpdate(uint64 updateId, uint8 custodianIndex) inline private {
        UpdateRequest request = m_updateRequests[updateId];
        request.signs++;
        request.confirmationsMask = _setConfirmed(request.confirmationsMask, custodianIndex);
        m_updateRequests[updateId] = request;
    }

    /// @dev Removes expired update requests.
    function _removeExpiredUpdateRequests() inline private {
        uint64 marker = _getExpirationBound();
        if (m_updateRequests.empty()) return;

        (uint64 updateId, UpdateRequest req) = m_updateRequests.min().get();
        bool needCleanup = updateId <= marker;
        if (needCleanup) {
            tvm.accept();
            while (needCleanup) {
                // request is expired, remove it
                _deleteUpdateRequest(updateId, req.index);
                optional(uint64, UpdateRequest) reqOpt = m_updateRequests.next(updateId);
                if (reqOpt.hasValue()) {
                    (updateId, req) = reqOpt.get();
                    needCleanup = updateId <= marker;
                } else {
                    needCleanup = false;
                }
            }
            tvm.commit();
        }
    }
	
	// ****************************************************************	
	// Inline
	// ****************************************************************		

    /// @dev Helper function to correctly delete request.
    function _deleteUpdateRequest(uint64 updateId, uint8 index) inline private {
        m_updateRequestsMask &= ~(uint32(1) << index);
        delete m_updateRequests[updateId];
    }	

    /// @dev Returns queued transaction count by custodian with defined index.
    function _getMaskValue(uint256 mask, uint8 index) inline private pure returns (uint8) {
        return uint8((mask >> (8 * uint256(index))) & 0xFF);
    }

    /// @dev Increment queued transaction count by custodian with defined index.
    function _incMaskValue(uint256 mask, uint8 index) inline private pure returns (uint256) {
        return mask + (1 << (8 * uint256(index)));
    }

    /// @dev Decrement queued transaction count by custodian with defined index.
    function _decMaskValue(uint256 mask, uint8 index) inline private pure returns (uint256) {
        return mask - (1 << (8 * uint256(index)));
    }

    /// @dev Checks bit with defined index in the mask.
    function _checkBit(uint32 mask, uint8 index) inline private pure returns (bool) {
        return (mask & (uint32(1) << index)) != 0;
    }

    /// @dev Checks if object is confirmed by custodian.
    function _isConfirmed(uint32 mask, uint8 custodianIndex) inline private pure returns (bool) {
        return _checkBit(mask, custodianIndex);
    }

    /// @dev Sets custodian confirmation bit in the mask.
    function _setConfirmed(uint32 mask, uint8 custodianIndex) inline private pure returns (uint32) {
        mask |= (uint32(1) << custodianIndex);
        return mask;
    }

    /// @dev Checks that custodian with supplied public key exists in custodian set.
    function _findCustodian(uint256 senderKey) inline private view returns (uint8) {
        optional(uint8) custodianIndex = m_custodians.fetch(senderKey);
        require(custodianIndex.hasValue(), 100);
        return custodianIndex.get();
    }

    /// @dev Generates new id for object.
    function _generateId() inline private pure returns (uint64) {
        return (uint64(now) << 32) | (tx.timestamp & 0xFFFFFFFF);
    }

    /// @dev Returns timestamp after which transactions are treated as expired.
    function _getExpirationBound() inline private pure returns (uint64) {
        return (uint64(now) - EXPIRATION_TIME) << 32;
    }

    /// @dev Returns transfer flags according to input value and `allBalance` flag.
    function _getSendFlags(uint128 value, bool allBalance) inline private pure returns (uint8, uint128) {
        uint8 flags = IGNORE_ERRORS | FEE_EXTRA;
        if (allBalance) {
            flags = IGNORE_ERRORS | ALL_BALANCE_GAS;
            value = 0;
        }
        return (flags, value);
    }
	
	// ****************************************************************	
	// Special
	// ****************************************************************	

    /// @dev SHOULD NOT BE RENAMED! Worker function after code update.
    function onCodeUpgrade(uint256[] newOwners, uint8 reqConfirms) private {
        tvm.resetStorage();
        _initialize(newOwners, reqConfirms);
    }
	
	modifier onlySingleOwner {
        require(m_custodianCount == 1, 108);
        require(msg.pubkey() == m_ownerKey, 100);
        tvm.accept();
		_;
	}	
}