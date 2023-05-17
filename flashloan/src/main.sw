contract;

use std::bytes::Bytes;
use std::call_frames::contract_id;
use std::context::this_balance;
use std::low_level_call::{call_with_function_selector_vec, CallParams};
use std::token::{burn, mint};

abi FlashLoan {
    #[payable]
    fn flashloan(amount: u64, target: ContractId, function_selector: Vec<u8>, calldata: Vec<u8>, single_copy_type: bool, gas_required: u64);

    fn flash_fee(amount: u64) -> u64;
}

enum FlashLoanError {
    // The loan was not repaid. The amount of the loan that was not repaid is returned.
    LoanNotRepaid: u64,
}

impl FlashLoan for Contract {
    /// `amount` : The amount of tokens to mint and forward to the target contract.
    /// `target` : The contract to call.
    /// `function_selector` : The function selector of the function to call on the target contract.
    /// `calldata` : The calldata to pass to the target contract.
    /// `single_copy_type` : Whether the calldata passed to the target contract is a single copy type (as opposed to a pointer)
    /// `gas_required` : The amount of gas to forward to the target contract.
    #[payable]
    fn flashloan(
        amount: u64,
        target: ContractId,
        function_selector: Vec<u8>,
        calldata: Vec<u8>,
        single_copy_type: bool,
        gas_required: u64,
    ) {
        // Mint tokens
        mint(amount);

        // Get the new "free balance" of the minting contract (this can be greater than `amount` if it was non-zero before)
        let free_balance = this_balance(contract_id());

        // Call the target as requested. 
        // Forward the minted coins, and the gas required
        // TODO : Possible to just forward all the remaining gas?
        call_with_function_selector_vec(target, function_selector, calldata, single_copy_type, CallParams {
            coins: amount,
            asset_id: contract_id(),
            gas: gas_required,
        });

        // Check that the loan has been repaid.
        // (compiler will warn about reentrancy here as we are reading the balance tree after an external call)
        let expected_balance_after_repay = flash_fee(amount) + free_balance;
        require(this_balance(contract_id()) >= expected_balance_after_repay, FlashLoanError::LoanNotRepaid(expected_balance_after_repay - this_balance(contract_id())));
        

        // Burn the tokens that were minted.
        burn(amount);
    }

    fn flash_fee(amount: u64) -> u64 {
        flash_fee(amount)
    }
}

fn flash_fee(amount: u64) -> u64 {
    amount * 10 / 10000 // 0.1% fee
}