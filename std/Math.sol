pragma ever-solidity ^0.64;

abstract contract Flags {

	// ****************************************************************	
	// Messages Flags
	// ****************************************************************	

	uint8 constant FEE_FROM_VALUE = 0; // Forward fee is subtracted from value sent
	uint8 constant FEE_EXTRA = 1; // Forward fee is subtracted sender's balance (in addition to sent value)
    uint8 constant IGNORE_ERRORS = 2;  // Any errors arising during the action phase should be ignored.
    uint8 constant SELF_DESTROY = 32; // Destroys sender contract (if balance is 0)
    uint8 constant ALL_MESSAGE_GAS = 64; // Sends all remaining gas of message
    uint8 constant ALL_BALANCE_GAS = 128; // Sends all remaining gas of balance (except reserved)
    uint8 constant SPEND_AND_DESTROY = ALL_BALANCE_GAS + SELF_DESTROY + IGNORE_ERRORS; // Sends all remaining gas of balance (except reserved)	

	// ****************************************************************	
	// RAWRESERVE Flags
	// ****************************************************************	
	
	// EXACT - exact specified value
	// POSSIBLE = min(value, remaining_balance), so it's possible value
	// PREV - original (pre-execution) balance
	uint8 constant RSRV_EXACT = 0; // 0 -> reserve = value nanotons.
	uint8 constant RSRV_ALL_EXCEPT_EXACT = 1; // 1 -> reserve = remaining_balance - value nanotons.
	uint8 constant RSRV_POSSIBLE = 2; // 2 -> reserve = min(value, remaining_balance) nanotons.
	uint8 constant RSRV_ALL_EXCEPT_POSSIBLE = 3; // 3 = 2 + 1 -> reserve = remaining_balance - min(value, remaining_balance) nanotons.
	uint8 constant RSRV_PREV_BALANCE_AND_EXACT = 4; // 4 -> reserve = original_balance + value nanotons.
	uint8 constant RSRV_ALL_EXCEPT_PREV_AND_EXACT = 5; // 5 = 4 + 1 -> reserve = remaining_balance - (original_balance + value) nanotons.
	uint8 constant RSRV_PREV_BALANCE_AND_VALUE_IF_POSSIBLE = 6; // 6 = 4 + 2 -> reserve = min(original_balance + value, remaining_balance) = remaining_balance nanotons.
	uint8 constant RSRV_ALL_EXCEPT_PREV_BALANCE_AND_EXACT_IF_POSSIBLE = 7; // 7 = 4 + 2 + 1 -> reserve = remaining_balance - min(original_balance + value, remaining_balance) nanotons.
	uint8 constant RSRV_PREV_BALANCE_EXCEPT_EXACT = 12; // 12 = 8 + 4 -> reserve = original_balance - value nanotons.
	uint8 constant RSRV_ALL_EXCEPT_PREV_BALANCE_EXCEPT_EXACT = 13; // 13 = 8 + 4 + 1 -> reserve = remaining_balance - (original_balance - value) nanotons.
	uint8 constant RSRV_PREV_BALANCE_AND_EXACT_IF_POSSIBLE = 14; // 14 = 8 + 4 + 2 -> reserve = min(original_balance - value, remaining_balance) nanotons.
	uint8 constant RSRV_ALL_EXCEPT_PREV_BALANCE_EXCEPT_EXACT_IF_POSSIBLE = 15; // 15 = 8 + 4 + 2 + 1 -> reserve = remaining_balance - min(original_balance - value, remaining_balance) nanotons.	
	
}