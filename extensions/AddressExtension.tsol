pragma ever-solidity ^0.64;

library AddressExtension {
	// Reserving constant amount of gas, so change return will pay correct sums
    function notNull(address address_) internal inline returns (bool) {
		return address_.value != 0;
	}
}