contract;

// A test contract with a function that can only be called if some value was forwarded
// The contract then forces the forwarded amount back to the sender,
// optionally underpaying by 1 to test repayment enforcement

use interfaces::{FlashBorrower};

use std::context::msg_amount;
use std::call_frames::msg_asset_id;
use std::token::force_transfer_to_contract;


impl FlashBorrower for Contract {
    #[payable]
    fn on_flash_loan(initiatior: Identity, fee: u64, data: Vec<u64>) {
        if msg_amount() < 100 {
            revert(42);
        };
        if data.get(0).unwrap() == 1 {
            force_transfer_to_contract(msg_amount() - 1, msg_asset_id(), msg_asset_id());
        } else {
            force_transfer_to_contract(msg_amount() + (msg_amount() * 10 / 1000), msg_asset_id(), msg_asset_id());
        };
    }
}
