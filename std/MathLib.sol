pragma ever-solidity ^0.64;

abstract contract MathLib {

	// ****************************************************************	
	// Price Math Support Functions
	// ****************************************************************	

	///@dev Reversed price for assets price pair
	///@notice EVER->USD becomes USD->EVER
    function $reversePrice(uint128 forwardPrice_, uint8 decimals_) internal inline pure returns (uint128)
    {
		require(decimals_ <= 18, 600, "MATH: More than 18 decimals isn't supported");
		uint64 ten = 10;
		uint64 decimalsUint = ten**decimals_;
		return math.muldivc(decimalsUint,
							decimalsUint, 
							forwardPrice_);
    }		

	///@dev Returns amount of exchanged asset
    function $exchange(uint128 amount_, uint128 price_, uint8 decimals_) internal inline pure returns (uint128)
    {
		require(decimals_ <= 18, 600, "MATH: More than 18 decimals isn't supported");
		uint64 ten = 10;
		uint64 decimalsUint = ten**decimals_;
		return math.muldiv( amount_,
							price_, 
							decimalsUint);
    }	
	
	function $swap(uint128[] array_, uint indexA_, uint indexB_) internal inline pure {
		(array_[indexA_], array_[indexB_]) = (array_[indexB_], array_[indexA_]);
	}
	
	function $avg(uint128 x, uint128 y) internal inline pure returns (uint128 result) {
		return 	(x >> 1) + 
				(y >> 1) + 
				(x & y & 1);
	}		
	
	function _sort(uint128[] array, uint begin, uint end) internal pure {
		if (begin < end) {
			uint j = begin;
			uint128 pivot = array[j];
			for (uint i = begin + 1; i < end; ++i) {
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
	
	function _mode(uint128[] array) internal pure returns (uint128) {
		uint128 modeValue; 
		uint[] count; 
		uint index; 
		uint maxIndex = 0;
		//uint zero=0;

		for (uint i = 0; i < array.length; i += 1) {
			index = array[i];
			count[index] = (count[index]) + 1;
			if (count[index] > count[maxIndex]) {
				maxIndex = index;
			}
		}

		for (uint i =0;i < count.length; i++)
			if (count[i] == maxIndex) {
					modeValue=count[i];
					break;
				}

		return modeValue;
	}
	
}