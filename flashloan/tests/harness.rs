use fuels::{prelude::*, tx::ContractId};

macro_rules! fn_selector {
    ( $fn_name: ident ( $($fn_arg: ty),* )  ) => {
         ::fuels::core::code_gen::function_selector::resolve_fn_selector(stringify!($fn_name), &[$( <$fn_arg as ::fuels::core::Parameterize>::param_type() ),*]).to_vec()
    }
}
macro_rules! calldata {
    ( $($arg: expr),* ) => {
        ::fuels::core::abi_encoder::ABIEncoder::encode(&[$(::fuels::core::Tokenizable::into_token($arg)),*]).unwrap().resolve(0)
    }
}

// Load abi from json
abigen!(Flashloan, "out/debug/flashloan-abi.json");

abigen!(
    Callee,
    "../flashloanCallee/out/debug/flashloanCallee-abi.json"
);

async fn get_contract_instances() -> (Flashloan, ContractId) {
    // Launch a local network and deploy the contract
    let mut wallets = launch_custom_provider_and_get_wallets(
        WalletsConfig::new(
            Some(1),             /* Single wallet */
            Some(1),             /* Single coin (UTXO) */
            Some(1_000_000_000), /* Amount per coin */
        ),
        None,
        None,
    )
    .await;

    let wallet = wallets.pop().unwrap();

    let id = Contract::deploy(
        "../flashloan/out/debug/flashloan.bin",
        &wallet,
        TxParameters::default(),
        StorageConfiguration::with_storage_path(Some(
            "../flashloan/out/debug/flashloan-storage_slots.json".to_string(),
        )),
    )
    .await
    .unwrap();
    let instance: Flashloan = Flashloan::new(id.clone(), wallet.clone());

    let callee_id = Contract::deploy(
        "../flashloanCallee/out/debug/flashloanCallee.bin",
        &wallet,
        TxParameters::default(),
        StorageConfiguration::with_storage_path(Some(
            "../flashloanCallee/out/debug/flashloanCallee-storage_slots.json".to_string(),
        )),
    )
    .await
    .unwrap();

    let callee_id: ContractId = callee_id.into();

    (instance, callee_id)
}

// TODO: Does not test the flash_fee being paid yet, as the flashloanCallee contract does not have extra coins to pay the fee
// Currently the fee is being rounded down to 0 so this test passes
#[tokio::test]
async fn can_flashloan() {
    let (instance, target) = get_contract_instances().await;

    let function_selector = fn_selector!(my_func(bool));
    let calldata = calldata!(false);

    let tx = instance
        .methods()
        .flashloan(100, target, function_selector, calldata, true, 1_000_000)
        .set_contracts(&[target.into()])
        .tx_params(TxParameters::default());
    let _result = tx.call().await.unwrap();
}

#[tokio::test]
#[should_panic(expected = "LoanNotRepaid")]
async fn reverts_if_not_fully_repaid() {
    let (instance, target) = get_contract_instances().await;

    let function_selector = fn_selector!(my_func(bool));
    let calldata = calldata!(true);

    let tx = instance
        .methods()
        .flashloan(100, target, function_selector, calldata, true, 1_000_000)
        .set_contracts(&[target.into()])
        .tx_params(TxParameters::default());
    let _result = tx.call().await.unwrap();
}
