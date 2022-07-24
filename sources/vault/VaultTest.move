#[test_only]
module TestVault::EscrowTests {
    use std::string;
    use std::signer;
    use std::unit_test;
    use std::vector;
    use aptos_framework::coin as Coin;

    use TestVault::Escrow;

    fun get_account(): signer {
        vector::pop_back(&mut unit_test::create_signers_for_testing(1))
    }

    #[test_only]
    struct CoinCapabilities has key {
        mint_cap: MintCapability<FakeMoney>,
        burn_cap: BurnCapability<FakeMoney>,
    }

    #[test]
    public entry fun init_deposit_withdraw_escrow() {
        let admin = get_account();
        let addr = signer::address_of(&admin);

        let name = string::utf8(b"Fake money");
        let symbol = string::utf8(b"FMD");

        let (mint_cap, burn_cap) = Coin::initialize<Escrow::ManagedCoin>(
            &admin,
            name,
            symbol,
            18,
            true
        );
        Coin::register<Escrow::ManagedCoin>(&admin);

        let coins_minted = Coin::mint<Escrow::ManagedCoin>(1000, &mint_cap);
        Coin::deposit(addr, coins_minted);

        move_to(&admin, CoinCapabilities {
            mint_cap,
            burn_cap
        });

        if (!Escrow::is_initialized_valut(addr)) {
            Escrow::init_escrow(&admin);
        };

        assert!(
          Escrow::get_vault_status(addr) == false,
          0
        );
        
        Escrow::pause_escrow(&admin);
        assert!(
          Escrow::get_vault_status(addr) == true,
          0
        );
        
        Escrow::resume_escrow(&admin);
        assert!(
          Escrow::get_vault_status(addr) == false,
          0
        );
        
        let user = get_account();
        let user_addr = signer::address_of(&user);

        Coin::register<Escrow::ManagedCoin>(&user);

        let coins_minted = Coin::mint<Escrow::ManagedCoin>(1000, &mint_cap);
        Coin::deposit(user_addr, coins_minted);

        move_to(&user, CoinCapabilities {
            mint_cap,
            burn_cap
        });

        // let to_mint = Coin::withdraw<Escrow::ManagedCoin>(&admin, 1000);
        // Coin::deposit(user_addr, to_mint);

        Escrow::deposit(&user, 10, addr);
        assert!(
          Escrow::get_user_info(user_addr) == 10,
          1
        );
    }
}
