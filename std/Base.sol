pragma ever-solidity ^0.64;

import "./Errors.sol";
import "./Flags.sol";

abstract contract Base is Errors, Flags {

	// ****************************************************************	
	// Contants
	// ****************************************************************		
	uint128 constant GAS_FLOOR = 25_000; // // 0.025 EVERs currently. IMPORTANT! this is Gas amount, not EVER amount!!! Use $toValue() to get EVERs
	
	// ****************************************************************	
	// Abstract
	// ****************************************************************		
    function $gasFloor() internal inline view returns (uint128 gasAmount);	
	
	// ****************************************************************	
	// Inlined Macros
	// ****************************************************************		
	// Reserving constant amount of gas, so change return will pay correct sums
    function $notNull(address addr) internal inline pure returns (bool isNull) {
		return addr.value != 0;
	}
	
	// Calculating real amount for paying needed gas
	function $toValue(uint128 gasAmount) internal inline pure returns (uint128 gasValue) {
		return gasToValue(gasAmount, address(this).wid);
	}
	
	// Reserving constant amount of gas, so change return will pay correct sums
    function $reserve(uint128 gasAmount) internal inline pure {
		tvm.rawReserve($toValue(gasAmount), 0);
	}	
	
	// Sending all change to address
	// $gasFloor() should be reserved on balance before doing this
	function $sendChange(address to) internal inline pure {
		to.transfer(0, true, ALL_BALANCE_GAS);
	}
    
	// ****************************************************************	
	// Modifiers
	// ****************************************************************	
	
	///@title Reserve Gas using gasToValue of $gasFloor() constant amount
	modifier reserveGas {
		$reserve($gasFloor());
		_;
	}

	///@title Reserve Gas using gasToValue of provided Gas amount
	modifier reserveGasExactly(uint128 gasAmount) {
		$reserve(gasAmount);
		_;
	}	

	///@title Checks message value against gasToValue of provided Gas amount
	modifier checkValue(uint128 gasAmount) {
		require(msg.value >= $toValue(gasAmount), NOT_ENOUGH_VALUE);
		_;
	}

	///@title Returns all balance of contract as a change (except reserved value)
	modifier returnAllUnreserved {    
		_;
		$sendChange(msg.sender);
	}

    	///@title Sends all balance of contract to provided address as a change (except reserved value)
	modifier returnAllUnreservedTo(address to) {
		_;
		$sendChange(to);
	}	
}