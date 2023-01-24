contract;

use std::bytes::Bytes;
use std::call_frames::contract_id;
use std::context::this_balance;
use std::low_level_call::{CallParams, call_with_function_selector_vec};
use std::token::{burn, mint};
use std::logging::log;

abi FlashLoan {
    fn flashloan(amount: u64, target: ContractId, function_selector: Vec<u8>, calldata: Vec<u8>, single_copy_type: bool, gas_required: u64);
}

enum FlashLoanError {
    LoanNotRepaid: u64,
}


impl FlashLoan for Contract {

    fn flashloan(amount: u64, target: ContractId, function_selector: Vec<u8>, calldata: Vec<u8>, single_copy_type: bool, gas_required: u64) {

        
        // Mint tokens
        mint(amount);

        // Get the new "free balance" of the minting contract (this can be greater than `amount` if it was non-zero before)
        let free_balance = self_balance();

        // Call the target as requested. 
        // Forward the minted coins, and the gas required
        // TODO : Possible to just forward all the remaining gas?
        call_with_function_selector_vec(target, function_selector, calldata, single_copy_type, CallParams{coins: amount, asset_id: contract_id(), gas: gas_required});

        // Check that the loan has been repaid.
        // (compiler will warn about reentrancy here as we are reading the balance tree after an external call)
        require(self_balance() >= free_balance, FlashLoanError::LoanNotRepaid(free_balance - self_balance()));

        // Burn the tokens that were minted.
        burn(amount);
    }
}

// Helper function for getting a contract's balance of its own asset
fn self_balance() -> u64 {
    this_balance(contract_id())
}