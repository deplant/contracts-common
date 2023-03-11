pragma ever-solidity ^0.64;

library TvmCellExtension {

	// Calculating contract address from stateInit
	function toAddress(TvmCell cell_) internal inline returns (address) {
		return address(tvm.hash(cell_));
	}	
	
	// Get hash and depth of cell
	function hashAndDepth(TvmCell cell_) internal inline returns (uint256,uint16) {
		return (tvm.hash(cell_),cell_.depth());
	}	
	
	function isEmpty(TvmCell cell_) internal inline returns (bool) {
		TvmBuilder builder;
		TvmCell emptyCell = builder.toCell();
		return (cell_ == emptyCell);
	}	
}