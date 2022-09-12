pragma ever-solidity ^0.64;

abstract contract Base {

	// ****************************************************************	
	// Contants
	// ****************************************************************		
	address constant ADDRESS_ZERO = address.makeAddrStd(0, 0);
	uint128 constant GAS_FLOOR = 25_000; // // 0.025 EVERs currently. IMPORTANT! this is Gas amount, not EVER amount!!! Use _toValue() to get EVERs
	uint64 constant SECOND = 1;
	uint64 constant MINUTE = 60;	
	
	// ****************************************************************	
	// Errors
	// ****************************************************************	
	// Security
	uint16 constant WRONG_CONSTRUCTOR_VALUES = 200;	
	uint16 constant NOT_MY_OWNER = 201;		
	// Gas
	uint16 constant NOT_ENOUGH_VALUE = 666;	
	
	// ****************************************************************	
	// Value Flags
	// ****************************************************************		
	uint8 constant FEE_FROM_VALUE = 0; // Forward fee is subtracted from value sent
	uint8 constant FEE_EXTRA = 1; // Forward fee is subtracted sender's balance
    uint8 constant IGNORE_ERRORS = 2;  // Any errors arising during the action phase should be ignored.
    uint8 constant SELF_DESTROY = 32; // Destroys sender contract (if balance is 0)
    uint8 constant ALL_MESSAGE_GAS = 64; // Sends all remaining gas of message
    uint8 constant ALL_BALANCE_GAS = 128; // Sends all remaining gas of balance (except reserved)
    uint8 constant SPEND_AND_DESTROY = ALL_BALANCE_GAS + SELF_DESTROY + IGNORE_ERRORS; // Sends all remaining gas of balance (except reserved)	
	
	// ****************************************************************	
	// Inlined Macros
	// ****************************************************************		
	// Reserving constant amount of gas, so change return will pay correct sums
    function _notNull(address addr) internal inline pure returns (bool isNull) {
		return addr.value != 0;
	}
	
	// Calculating real amount for paying needed gas
	function _toValue(uint128 gasAmount) internal inline pure returns (uint128 gasValue) {
		return gasToValue(gasAmount, address(this).wid);
	}
	
	// Reserving constant amount of gas, so change return will pay correct sums
    function _reserve(uint128 gasAmount) internal inline pure {
		tvm.rawReserve(_toValue(gasAmount), 0);
	}	
	
	// Sending all change to address
	// GAS_FLOOR should be reserved on balance before doing this
	function _sendChange(address to) internal inline pure {
		to.transfer(0, true, ALL_BALANCE_GAS);
	}
    
	// ****************************************************************	
	// Modifiers
	// ****************************************************************	
	modifier checkExtOwnerAndAccept {
		require(msg.pubkey() == tvm.pubkey(), NOT_MY_OWNER);
		tvm.accept();
		_;
	}
	
	///@title Reserve Gas using gasToValue of GAS_FLOOR constant amount
	modifier reserveGas {
		_reserve(GAS_FLOOR);
		_;
	}

	///@title Reserve Gas using gasToValue of provided Gas amount
	modifier reserveGasExactly(uint128 gasAmount) {
		_reserve(gasAmount);
		_;
	}	

	///@title Checks message value against gasToValue of provided Gas amount
	modifier checkValue(uint128 gasAmount) {
		require(msg.value >= _toValue(gasAmount), NOT_ENOUGH_VALUE);
		_;
	}

	///@title Returns all balance of contract as a change (except reserved value)
	modifier returnAllUnreserved {    
		_;
		_sendChange(msg.sender);
	}

    	///@title Sends all balance of contract to provided address as a change (except reserved value)
	modifier returnAllUnreservedTo(address to) {
		_;
		_sendChange(to);
	}	
}