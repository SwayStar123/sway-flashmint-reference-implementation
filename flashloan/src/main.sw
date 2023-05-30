contract;

use interfaces::{FlashMinter, FlashLoanError, FlashBorrower};

use std::bytes::Bytes;
use std::call_frames::contract_id;
use std::context::this_balance;
use std::low_level_call::{call_with_function_selector_vec, CallParams};
use std::token::{burn, mint};

impl FlashMinter for Contract {
    /// `amount` : The amount of tokens to mint and forward to the target contract.
    /// `target` : The contract to call.
    /// `calldata` : The calldata to pass to the borrower contract.
    /// `gas_required` : The amount of gas to forward to the borrower contract.
    fn flash_mint(
        amount: u64,
        target: ContractId,
        calldata: Vec<u8>,
        gas_required: u64,
    ) {
        require(amount <= max_flash_mint(), FlashLoanError::AmountOverMaximum);
        // Mint tokens
        mint(amount);

        // Get the new "free balance" of the minting contract (this can be greater than `amount` if it was non-zero before)
        let free_balance = this_balance(contract_id());

        // Call the target as requested. 
        // Forward the minted coins, and the gas required
        let borrower = abi(FlashBorrower, target.into());

        let fee = flash_fee(amount);

        borrower.on_flash_loan{
            gas: gas_required, // TODO : Possible to just forward all the remaining gas?
            coins: amount,
            asset_id: contract_id().into(),
        }(msg_sender().unwrap(), fee, calldata);

        // Check that the loan has been repaid.
        // (compiler will warn about reentrancy here as we are reading the balance tree after an external call)
        let expected_balance_after_repay = fee + free_balance;
        require(this_balance(contract_id()) >= expected_balance_after_repay, FlashLoanError::LoanNotRepaid(expected_balance_after_repay - this_balance(contract_id())));
        
        // Burn the tokens that were minted.
        burn(amount);
    }

    fn flash_fee(amount: u64) -> u64 {
        flash_fee(amount)
    }

    fn max_flash_mint() -> u64 {
        max_flash_mint()
    }
}

fn flash_fee(amount: u64) -> u64 {
    amount * 10 / 1000 // 1% fee
}

fn max_flash_mint() -> u64 {
    1_000_000_000_000
}