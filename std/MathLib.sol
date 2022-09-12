pragma ever-solidity ^0.64;

abstract contract MathLib {

	// ****************************************************************	
	// Price Math Support Functions
	// ****************************************************************	

	///@title Reversed price for assets price pair
	///@notice EVER->USD becomes USD->EVER
    function $reversePrice(uint128 forwardPrice_, uint8 decimals_) internal inline pure returns (uint128)
    {
		return math.muldivc(
							10**decimals_,
							10**decimals_, 
							forwardPrice_
		);
    }		

	///@title Returns amount of exchanged asset
    function $exchange(uint128 amount_, uint128 price_, uint8 decimals_) internal inline pure returns (uint128)
    {
		return math.muldiv(
							amount_,
							price_, 
							10**decimals_
		);
    }	

}