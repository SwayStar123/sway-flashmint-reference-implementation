contract;

// A test contract with a function that can only be called if some value was forwarded
// The contract then forces the forwarded amount back to the sender,
// optionally underpaying by 1 to test repayment enforcement
use std::context::msg_amount;
use std::call_frames::msg_asset_id;
use std::token::force_transfer_to_contract;

abi Callee {
    fn my_func(underpay: bool);
}

impl Callee for Contract {
    fn my_func(underpay: bool) {
        if msg_amount() < 100 {
            revert(42);
        };
        if underpay {
            force_transfer_to_contract(msg_amount() - 1, msg_asset_id(), msg_asset_id());
        } else {
            force_transfer_to_contract(msg_amount() + (msg_amount() * 10 / 1000), msg_asset_id(), msg_asset_id());
        };
    }
}
