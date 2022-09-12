pragma ever-solidity ^0.64;

abstract contract Flags {

	// ****************************************************************	
	// Message Flags
	// ****************************************************************	
	// Main flags
	uint8 constant EXACT_VALUE_GAS = 0; // Sends exact 'value' amount of EVERs
    uint8 constant ALL_MESSAGE_GAS = 64; // Sends all EVERs that came with this message (value is ignored)
    uint8 constant ALL_BALANCE_GAS = 128; // Sends all remaining EVERs of this contract (value is ignored)
	// Additional flags
	uint8 constant FEE_EXTRA = 1; // Subtract extra funds from sender's balance to pay forward fee
    uint8 constant IGNORE_ERRORS = 2;  // Any errors arising during the action phase should be ignored.
    uint8 constant SELF_DESTROY = 32; // Try to destroy sender contract (if balance is 0)
	// Complex examples
    uint8 constant DRAIN_AND_DESTROY = ALL_BALANCE_GAS + SELF_DESTROY + IGNORE_ERRORS;	
	
	// ****************************************************************	
	// RAWRESERVE Flags
	// ****************************************************************	
	
	uint8 constant RSRV_EXACT = 0; // 0 -> reserve = value nanotons.
	uint8 constant RSRV_ALL_EXCEPT_EXACT = 1; // 1 -> reserve = remaining_balance - value nanotons.
	uint8 constant RSRV_POSSIBLE = 2; // 2 -> reserve = min(value, remaining_balance) nanotons.
	uint8 constant RSRV_3 = 3; // 3 = 2 + 1 -> reserve = remaining_balance - min(value, remaining_balance) nanotons.
	uint8 constant RSRV_4 = 4; // 4 -> reserve = original_balance + value nanotons.
	uint8 constant RSRV_5 = 5; // 5 = 4 + 1 -> reserve = remaining_balance - (original_balance + value) nanotons.
	uint8 constant RSRV_6 = 6; // 6 = 4 + 2 -> reserve = min(original_balance + value, remaining_balance) = remaining_balance nanotons.
	uint8 constant RSRV_7 = 7; // 7 = 4 + 2 + 1 -> reserve = remaining_balance - min(original_balance + value, remaining_balance) nanotons.
	uint8 constant RSRV_12 = 12; // 12 = 8 + 4 -> reserve = original_balance - value nanotons.
	uint8 constant RSRV_13 = 13; // 13 = 8 + 4 + 1 -> reserve = remaining_balance - (original_balance - value) nanotons.
	uint8 constant RSRV_14 = 14; // 14 = 8 + 4 + 2 -> reserve = min(original_balance - value, remaining_balance) nanotons.
	uint8 constant RSRV_15 = 15; // 15 = 8 + 4 + 2 + 1 -> reserve = remaining_balance - min(original_balance - value, remaining_balance) nanotons.
	
}