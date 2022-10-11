# Common Contracts

This repository stores common contracts made by Deplant.

## STD

Library with common functions (only internal and mostly inlined),
modifiers, constants, rules and strategies.

### Floor & Reserve Gas Management Strategy

[Gas Management](std/GasManagement.sol) - abstract contract with
internal functions & modifiers for gas management
strategy where you always reserve a certain amount of gas on
your contract and return all EVERs above this floor to
contract's counterparties.

Contract has one `virtual` function `$gasFloor()` that you need
to `override` like this:

```solidity
function $gasFloor() override internal inline view returns (uint128 gasAmount) {
    return DEFAULT_GAS_FLOOR;
}
```

DEFAULT_GAS_FLOOR is 25000 gas. You can specify your own value for floor. All functions and modifiers will use this gas
floor.

Typical usage of modifiers is:

```solidity
function publishCustomTask() external view internalMsg reserveGas returnAllUnreserved {
 // reserveGas() modifier will reserve gas floor at the beginning
 // returnAllUnreserved() modifier will return all extra gas to sender at the end
}

address _owner;

function publishCustomTask() external view internalMsg reserveGasExactly(25_000) returnAllUnreservedTo(_ownerAddress) {
 // reserveGasExactly(25_000) modifier will reserve 25000 gas as a floor
 // returnAllUnreservedTo(_ownerAddress) modifier will return all extra gas to address variable _owner
}
```

### Ownership

Abstract contracts to help with ownership management.

* [Externally Owned](std/ExternallyOwned.sol) - common modifiers for externally-owned contract
* [Internally Owned](std/InternallyOwned.sol) - common modifier for internally-owned contracts

### Math

[Math Library](std/MathLib.sol) contains a lot of useful
Solidity math (sorts, averages, price convertations), still,
it's not final and not for everyone, so use it as a copy/paste source.

### Constants

These are constants that are used by everyone & everywhere:

* [Errors](std/Errors.sol) - common exception constants for almost any contract
* [Flags](std/Flags.sol) - common flag constants for message transfers & gas reserve

## Extensions

[Address Type Extension](extensions/AddressExtension.sol) contains various
useful functions for extending Address type.

[TvmCell Type Extension](extensions/TvmCellExtension.sol) contains various
useful functions for extending TvmCell type.