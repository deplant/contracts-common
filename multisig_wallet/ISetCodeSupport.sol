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

/// @title Additional SetCode functionality for Multi Signature Wallet 3.0 Interface (can deploy other contracts, can choose transaction expiration time)
/// @author deplant (https://github.com/deplant)
interface ISetCodeSupport {

	// ****************************************************************	
	// Types
	// ****************************************************************	

    /// Request for code update
    struct UpdateRequest {
        // request id
        uint64 id;
        // index of custodian submitted request
        uint8 index;
        // number of confirmations from custodians
        uint8 signs;
        // confirmation binary mask
        uint32 confirmationsMask;
        // public key of custodian submitted request
        uint256 creator;
        // hash from code's tree of cells
        uint256 codeHash;
        // array with new wallet custodians
        uint256[] custodians;
        // Default number of confirmations required to execute transaction
        uint8 reqConfirms;
    }
	
	// ****************************************************************	
	// External 
	// ****************************************************************		

    /// @title Allows to submit update request. New custodians can be supplied.
    /// @param codeHash Representation hash of code's tree of cells.
    /// @param owners Array with new custodians.
    /// @param reqConfirms Default number of confirmations required for executing transaction.
    /// @return updateId Id of submitted update request.
    function submitUpdate(uint256 codeHash, uint256[] owners, uint8 reqConfirms) public 
        returns (uint64 updateId);

    /// @title Allow to confirm submitted update request. Call executeUpdate to do `setcode`
    /// after necessary confirmation count.
    /// @param updateId Id of submitted update request.
    function confirmUpdate(uint64 updateId) public;

    /// @title Allows to execute confirmed update request.
    /// @param updateId Id of update request.
    /// @param code Root cell of tree of cells with contract code.
    function executeUpdate(uint64 updateId, TvmCell code) public;
	
	// ****************************************************************	
	// Getters
	// ****************************************************************		

    /// @title Get-method to query all pending update requests.
    function getUpdateRequests() public view returns (UpdateRequest[] updates);
   
}