pragma ever-solidity ^0.64;

abstract contract Errors {

	// ****************************************************************	
	// Solidity Runtime Exceptions
	// ****************************************************************	

	/*
	* 40 - External inbound message has an invalid signature. See tvm.pubkey() and msg.pubkey().
	* 50 - Array index or index of <mapping>.at() is out of range.
	* 51 - Contract's constructor has already been called.
	* 52 - Replay protection exception. 
	* 53 - See <address>.unpack().
	* 54 - <array>.pop call for an empty array.
	* 55 - See tvm.insertPubkey().
	* 57 - External inbound message is expired. 
	* 58 - External inbound message has no signature but has public key. 
	* 60 - Inbound message has wrong function id. In the contract there are no functions with such function id and there is no fallback function that could handle the message. See fallback.
	* 61 - Deploying StateInit has no public key in data field.
	* 62 - Reserved for internal usage.
	* 63 - See <optional(Type)>.get().
	* 64 - tvm.buildExtMSg() call with wrong parameters. See tvm.buildExtMsg().
	* 65 - Call of the unassigned variable of function type. See Function type.
	* 66 - Convert an integer to a string with width less than number length. See format().
	* 67 - See gasToValue and valueToGas.
	* 68 - There is no config parameter 20 or 21.
	* 69 - Zero to the power of zero calculation (0**0 in solidity style or 0^0).
	* 70 - string method substr was called with substr longer than the whole string.
	* 71 - Function marked by externalMsg was called by internal message.
	* 72 - Function marked by internalMsg was called by external message.
	* 73 - The value can't be converted to enum type.
	* 74 - Await answer message has wrong source address.
	* 75 - Await answer message has wrong function id.
	* 76 - Public function was called before constructor.
	* 77 - It's impossible to convert variant type to target type. See variant.toUint()
	*/
	
	// ****************************************************************	
	// User Exceptions (error codes >= 100)
	// ****************************************************************		

	// Security
	uint16 constant WRONG_CONSTRUCTOR_VALUES = 200;	
	uint16 constant NOT_MY_OWNER = 201;		
	// Gas
	uint16 constant NOT_ENOUGH_VALUE = 666;	
	
}