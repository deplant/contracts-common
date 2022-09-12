pragma ever-solidity ^0.64;

import "./Errors.sol";

abstract contract InternallyOwned is Errors {

    function $intOwner() internal inline view returns (address owner);

	// ****************************************************************	
	// Modifiers
	// ****************************************************************	
	modifier onlyIntOwner {
		require(msg.sender.value == $intOwner().value, NOT_MY_OWNER);
		_;
	}
	
}