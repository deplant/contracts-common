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
	
	function $swap(int128[] array_, uint128 indexA_, uint128 indexB_) internal inline pure {
		(array_[indexA_], array_[indexB_]) = (array_[indexB_], array_[indexA_]);
	}
	
	function $avg(uint128 x, uint128 y) internal inline pure returns (uint128 result) {
		return 	(x >> 1) + 
				(y >> 1) + 
				(x & y & 1);
	}		
	
	function _sort(int256[] array, uint256 begin, uint256 end) internal pure {
		if (begin < end) {
			uint256 j = begin;
			int256 pivot = array[j];
			for (uint256 i = begin + 1; i < end; ++i) {
				if (array[i] < pivot) {
					$swap(array, i, ++j);
				}
			}
			$swap(array, begin, j);
			_sort(array, begin, j);
			_sort(array, j + 1, end);
		}
	}	
	
	function _median(uint128[] sortedArray_, uint length_) internal pure returns(uint128) {
		//sort(array, 0, length);
		return length_ % 2 == 0 
				? 
				$avg(sortedArray_[length_/2-1], sortedArray_[length_/2]) 
				: 
				sortedArray_[length_/2];
	}
	
}