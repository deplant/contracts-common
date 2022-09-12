pragma ever-solidity ^0.64;

import "./Errors.sol";

abstract contract ExternallyOwned is Errors {

	// ****************************************************************	
	// Modifiers
	// ****************************************************************	
	modifier checkExtOwnerAndAccept {
		require(msg.pubkey() == tvm.pubkey(), NOT_MY_OWNER);
		tvm.accept();
		_;
	}
	
}