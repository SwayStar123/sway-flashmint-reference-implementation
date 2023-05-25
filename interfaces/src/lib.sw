library;

pub enum FlashLoanError {
    // The loan was not repaid. The amount of the loan that was not repaid is returned.
    LoanNotRepaid: u64,
}

abi FlashMinter {
    fn flash_mint(amount: u64,
        target: ContractId,
        calldata: Vec<u8>,
        gas_required: u64,);

    fn flash_fee(amount: u64) -> u64;
}

abi FlashBorrower {
    #[payable]
    fn on_flash_loan(initiatior: Identity, fee: u64, data: Vec<u64>);
}