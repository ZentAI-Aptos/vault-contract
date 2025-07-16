module 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap {
    struct AddLiquidityEvent<phantom T0, phantom T1> has drop, store {
        user: address,
        amount_x: u64,
        amount_y: u64,
        liquidity: u64,
        fee_amount: u64,
    }
    
    struct LPToken<phantom T0, phantom T1> has key {
        dummy_field: bool,
    }
    
    struct PairCreatedEvent has drop, store {
        user: address,
        token_x: 0x1::string::String,
        token_y: 0x1::string::String,
    }
    
    struct PairEventHolder<phantom T0, phantom T1> has key {
        add_liquidity: 0x1::event::EventHandle<AddLiquidityEvent<T0, T1>>,
        remove_liquidity: 0x1::event::EventHandle<RemoveLiquidityEvent<T0, T1>>,
        swap: 0x1::event::EventHandle<SwapEvent<T0, T1>>,
    }
    
    struct RemoveLiquidityEvent<phantom T0, phantom T1> has drop, store {
        user: address,
        liquidity: u64,
        amount_x: u64,
        amount_y: u64,
        fee_amount: u64,
    }
    
    struct SwapEvent<phantom T0, phantom T1> has drop, store {
        user: address,
        amount_x_in: u64,
        amount_y_in: u64,
        amount_x_out: u64,
        amount_y_out: u64,
    }
    
    struct SwapInfo has key {
        signer_cap: 0x1::account::SignerCapability,
        fee_to: address,
        admin: address,
        pair_created: 0x1::event::EventHandle<PairCreatedEvent>,
    }
    
    struct TokenPairMetadata<phantom T0, phantom T1> has key {
        creator: address,
        fee_amount: 0x1::coin::Coin<LPToken<T0, T1>>,
        k_last: u128,
        balance_x: 0x1::coin::Coin<T0>,
        balance_y: 0x1::coin::Coin<T1>,
        mint_cap: 0x1::coin::MintCapability<LPToken<T0, T1>>,
        burn_cap: 0x1::coin::BurnCapability<LPToken<T0, T1>>,
        freeze_cap: 0x1::coin::FreezeCapability<LPToken<T0, T1>>,
    }
    
    struct TokenPairReserve<phantom T0, phantom T1> has key {
        reserve_x: u64,
        reserve_y: u64,
        block_timestamp_last: u64,
    }
    
    fun update<T0, T1>(arg0: u64, arg1: u64, arg2: &mut TokenPairReserve<T0, T1>) {
        arg2.reserve_x = arg0;
        arg2.reserve_y = arg1;
        arg2.block_timestamp_last = 0x1::timestamp::now_seconds();
    }
    
    fun burn<T0, T1>(arg0: 0x1::coin::Coin<LPToken<T0, T1>>) : (0x1::coin::Coin<T0>, 0x1::coin::Coin<T1>, u64) acquires TokenPairMetadata, TokenPairReserve {
        let v0 = borrow_global_mut<TokenPairMetadata<T0, T1>>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa);
        let v1 = borrow_global_mut<TokenPairReserve<T0, T1>>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa);
        let v2 = 0x1::coin::value<LPToken<T0, T1>>(&arg0);
        let v3 = total_lp_supply<T0, T1>();
        let v4 = ((0x1::coin::value<T0>(&v0.balance_x) as u128) * (v2 as u128) / (v3 as u128)) as u64;
        let v5 = ((0x1::coin::value<T1>(&v0.balance_y) as u128) * (v2 as u128) / (v3 as u128)) as u64;
        assert!(v4 > 0 && v5 > 0, 10);
        0x1::coin::burn<LPToken<T0, T1>>(arg0, &v0.burn_cap);
        update<T0, T1>(0x1::coin::value<T0>(&v0.balance_x), 0x1::coin::value<T1>(&v0.balance_y), v1);
        v0.k_last = (v1.reserve_x as u128) * (v1.reserve_y as u128);
        (extract_x<T0, T1>(v4 as u64, v0), extract_y<T0, T1>(v5 as u64, v0), mint_fee<T0, T1>(v1.reserve_x, v1.reserve_y, v0))
    }
    
    fun mint<T0, T1>() : (0x1::coin::Coin<LPToken<T0, T1>>, u64) acquires TokenPairMetadata, TokenPairReserve {
        let v0 = borrow_global_mut<TokenPairMetadata<T0, T1>>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa);
        let v1 = 0x1::coin::value<T0>(&v0.balance_x);
        let v2 = 0x1::coin::value<T1>(&v0.balance_y);
        let v3 = borrow_global_mut<TokenPairReserve<T0, T1>>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa);
        let v4 = total_lp_supply<T0, T1>();
        let v5 = if (v4 == 0) {
            let v6 = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::math::sqrt(((v1 as u128) - (v3.reserve_x as u128)) * ((v2 as u128) - (v3.reserve_y as u128)));
            assert!(v6 > 1000, 4);
            mint_lp_to<T0, T1>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa, 1000 as u64, &v0.mint_cap);
            v6 - 1000
        } else {
            let v7 = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::math::min(((v1 as u128) - (v3.reserve_x as u128)) * v4 / (v3.reserve_x as u128), ((v2 as u128) - (v3.reserve_y as u128)) * v4 / (v3.reserve_y as u128));
            assert!(v7 > 0, 4);
            v7
        };
        update<T0, T1>(v1, v2, v3);
        v0.k_last = (v3.reserve_x as u128) * (v3.reserve_y as u128);
        (mint_lp<T0, T1>(v5 as u64, &v0.mint_cap), mint_fee<T0, T1>(v3.reserve_x, v3.reserve_y, v0))
    }
    
    fun swap<T0, T1>(arg0: u64, arg1: u64) : (0x1::coin::Coin<T0>, 0x1::coin::Coin<T1>) acquires TokenPairMetadata, TokenPairReserve {
        assert!(arg0 > 0 || arg1 > 0, 13);
        let v0 = borrow_global_mut<TokenPairReserve<T0, T1>>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa);
        assert!(arg0 < v0.reserve_x && arg1 < v0.reserve_y, 7);
        let v1 = borrow_global_mut<TokenPairMetadata<T0, T1>>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa);
        let v2 = 0x1::coin::zero<T0>();
        let v3 = 0x1::coin::zero<T1>();
        if (arg0 > 0) {
            0x1::coin::merge<T0>(&mut v2, extract_x<T0, T1>(arg0, v1));
        };
        if (arg1 > 0) {
            0x1::coin::merge<T1>(&mut v3, extract_y<T0, T1>(arg1, v1));
        };
        let (v4, v5) = token_balances<T0, T1>();
        let v6 = if (v4 > v0.reserve_x - arg0) {
            v4 - v0.reserve_x - arg0
        } else {
            0
        };
        let v7 = if (v5 > v0.reserve_y - arg1) {
            v5 - v0.reserve_y - arg1
        } else {
            0
        };
        assert!(v6 > 0 || v7 > 0, 14);
        let v8 = 10000 as u128;
        let v9 = (v4 as u128) * v8 - (v6 as u128) * 25;
        let v10 = (v5 as u128) * v8 - (v7 as u128) * 25;
        let v11 = (v0.reserve_x as u128) * v8;
        let v12 = (v0.reserve_y as u128) * v8;
        assert!(v9 > 0 && v11 > 0 && 340282366920938463463374607431768211455 / v9 > v10 && 340282366920938463463374607431768211455 / v11 > v12 && v9 * v10 >= v11 * v12 || (v9 as u256) * (v10 as u256) >= (v11 as u256) * (v12 as u256), 15);
        update<T0, T1>(v4, v5, v0);
        (v2, v3)
    }
    
    public(friend) fun add_liquidity<T0, T1>(arg0: &signer, arg1: u64, arg2: u64) : (u64, u64, u64) acquires PairEventHolder, TokenPairMetadata, TokenPairReserve {
        let (v0, v1, v2, v3, v4, v5) = add_liquidity_direct<T0, T1>(0x1::coin::withdraw<T0>(arg0, arg1), 0x1::coin::withdraw<T1>(arg0, arg2));
        let v6 = v2;
        let v7 = 0x1::signer::address_of(arg0);
        let v8 = 0x1::coin::value<LPToken<T0, T1>>(&v6);
        assert!(v8 > 0, 7);
        check_or_register_coin_store<LPToken<T0, T1>>(arg0);
        0x1::coin::deposit<LPToken<T0, T1>>(v7, v6);
        0x1::coin::deposit<T0>(v7, v4);
        0x1::coin::deposit<T1>(v7, v5);
        let v9 = AddLiquidityEvent<T0, T1>{
            user       : v7, 
            amount_x   : v0, 
            amount_y   : v1, 
            liquidity  : v8, 
            fee_amount : v3 as u64,
        };
        0x1::event::emit_event<AddLiquidityEvent<T0, T1>>(&mut borrow_global_mut<PairEventHolder<T0, T1>>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa).add_liquidity, v9);
        (v0, v1, v8)
    }
    
    fun add_liquidity_direct<T0, T1>(arg0: 0x1::coin::Coin<T0>, arg1: 0x1::coin::Coin<T1>) : (u64, u64, 0x1::coin::Coin<LPToken<T0, T1>>, u64, 0x1::coin::Coin<T0>, 0x1::coin::Coin<T1>) acquires TokenPairMetadata, TokenPairReserve {
        let v0 = 0x1::coin::value<T0>(&arg0);
        let v1 = 0x1::coin::value<T1>(&arg1);
        let (v2, v3, _) = token_reserves<T0, T1>();
        let (v5, v6) = if (v2 == 0 && v3 == 0) {
            (v0, v1)
        } else {
            let v7 = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::quote(v0, v2, v3);
            let (v8, v9) = if (v7 <= v1) {
                (v0, v7)
            } else {
                let v10 = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::quote(v1, v3, v2);
                assert!(v10 <= v0, 8);
                (v10, v1)
            };
            (v8, v9)
        };
        assert!(v5 <= v0, 6);
        assert!(v6 <= v1, 6);
        deposit_x<T0, T1>(arg0);
        deposit_y<T0, T1>(arg1);
        let (v11, v12) = mint<T0, T1>();
        (v5, v6, v11, v12, 0x1::coin::extract<T0>(&mut arg0, v0 - v5), 0x1::coin::extract<T1>(&mut arg1, v1 - v6))
    }
    
    public(friend) fun add_swap_event<T0, T1>(arg0: &signer, arg1: u64, arg2: u64, arg3: u64, arg4: u64) acquires PairEventHolder {
        let v0 = SwapEvent<T0, T1>{
            user         : 0x1::signer::address_of(arg0), 
            amount_x_in  : arg1, 
            amount_y_in  : arg2, 
            amount_x_out : arg3, 
            amount_y_out : arg4,
        };
        0x1::event::emit_event<SwapEvent<T0, T1>>(&mut borrow_global_mut<PairEventHolder<T0, T1>>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa).swap, v0);
    }
    
    public(friend) fun add_swap_event_with_address<T0, T1>(arg0: address, arg1: u64, arg2: u64, arg3: u64, arg4: u64) acquires PairEventHolder {
        let v0 = SwapEvent<T0, T1>{
            user         : arg0, 
            amount_x_in  : arg1, 
            amount_y_in  : arg2, 
            amount_x_out : arg3, 
            amount_y_out : arg4,
        };
        0x1::event::emit_event<SwapEvent<T0, T1>>(&mut borrow_global_mut<PairEventHolder<T0, T1>>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa).swap, v0);
    }
    
    public fun admin() : address acquires SwapInfo {
        borrow_global_mut<SwapInfo>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa).admin
    }
    
    public fun check_or_register_coin_store<T0>(arg0: &signer) {
        if (!0x1::coin::is_account_registered<T0>(0x1::signer::address_of(arg0))) {
            0x1::coin::register<T0>(arg0);
        };
    }
    
    public(friend) fun create_pair<T0, T1>(arg0: &signer) acquires SwapInfo {
        assert!(!is_pair_created<T0, T1>(), 1);
        let v0 = 0x1::signer::address_of(arg0);
        let v1 = borrow_global_mut<SwapInfo>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa);
        let v2 = 0x1::account::create_signer_with_capability(&v1.signer_cap);
        let v3 = 0x1::string::utf8(b"Pancake-");
        0x1::string::append(&mut v3, 0x1::coin::symbol<T0>());
        0x1::string::append_utf8(&mut v3, b"-");
        0x1::string::append(&mut v3, 0x1::coin::symbol<T1>());
        0x1::string::append_utf8(&mut v3, b"-LP");
        if (0x1::string::length(&v3) > 32) {
            v3 = 0x1::string::utf8(b"Pancake LPs");
        };
        let (v4, v5, v6) = 0x1::coin::initialize<LPToken<T0, T1>>(&v2, v3, 0x1::string::utf8(b"Cake-LP"), 8, true);
        let v7 = TokenPairReserve<T0, T1>{
            reserve_x            : 0, 
            reserve_y            : 0, 
            block_timestamp_last : 0,
        };
        move_to<TokenPairReserve<T0, T1>>(&v2, v7);
        let v8 = TokenPairMetadata<T0, T1>{
            creator    : v0, 
            fee_amount : 0x1::coin::zero<LPToken<T0, T1>>(), 
            k_last     : 0, 
            balance_x  : 0x1::coin::zero<T0>(), 
            balance_y  : 0x1::coin::zero<T1>(), 
            mint_cap   : v6, 
            burn_cap   : v4, 
            freeze_cap : v5,
        };
        move_to<TokenPairMetadata<T0, T1>>(&v2, v8);
        let v9 = PairEventHolder<T0, T1>{
            add_liquidity    : 0x1::account::new_event_handle<AddLiquidityEvent<T0, T1>>(&v2), 
            remove_liquidity : 0x1::account::new_event_handle<RemoveLiquidityEvent<T0, T1>>(&v2), 
            swap             : 0x1::account::new_event_handle<SwapEvent<T0, T1>>(&v2),
        };
        move_to<PairEventHolder<T0, T1>>(&v2, v9);
        let v10 = PairCreatedEvent{
            user    : v0, 
            token_x : 0x1::type_info::type_name<T0>(), 
            token_y : 0x1::type_info::type_name<T1>(),
        };
        0x1::event::emit_event<PairCreatedEvent>(&mut v1.pair_created, v10);
        register_lp<T0, T1>(&v2);
    }
    
    fun deposit_x<T0, T1>(arg0: 0x1::coin::Coin<T0>) acquires TokenPairMetadata {
        0x1::coin::merge<T0>(&mut borrow_global_mut<TokenPairMetadata<T0, T1>>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa).balance_x, arg0);
    }
    
    fun deposit_y<T0, T1>(arg0: 0x1::coin::Coin<T1>) acquires TokenPairMetadata {
        0x1::coin::merge<T1>(&mut borrow_global_mut<TokenPairMetadata<T0, T1>>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa).balance_y, arg0);
    }
    
    fun extract_x<T0, T1>(arg0: u64, arg1: &mut TokenPairMetadata<T0, T1>) : 0x1::coin::Coin<T0> {
        assert!(0x1::coin::value<T0>(&arg1.balance_x) > arg0, 6);
        0x1::coin::extract<T0>(&mut arg1.balance_x, arg0)
    }
    
    fun extract_y<T0, T1>(arg0: u64, arg1: &mut TokenPairMetadata<T0, T1>) : 0x1::coin::Coin<T1> {
        assert!(0x1::coin::value<T1>(&arg1.balance_y) > arg0, 6);
        0x1::coin::extract<T1>(&mut arg1.balance_y, arg0)
    }
    
    public fun fee_to() : address acquires SwapInfo {
        borrow_global_mut<SwapInfo>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa).fee_to
    }
    
    fun init_module(arg0: &signer) {
        let v0 = 0x1::resource_account::retrieve_resource_account_cap(arg0, @0xf9d24010ad96659ee980598ff3848911253bda014e8fe59ce40e9eed9f6585a);
        let v1 = 0x1::account::create_signer_with_capability(&v0);
        let v2 = SwapInfo{
            signer_cap   : v0, 
            fee_to       : @0x0, 
            admin        : @0xa2c656b06aeff1406fd5ff837fa5b07825437a5f1ce6d75cad3f4e5c39ea955b, 
            pair_created : 0x1::account::new_event_handle<PairCreatedEvent>(&v1),
        };
        move_to<SwapInfo>(&v1, v2);
    }
    
    public fun is_pair_created<T0, T1>() : bool {
        exists<TokenPairReserve<T0, T1>>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa)
    }
    
    public fun lp_balance<T0, T1>(arg0: address) : u64 {
        0x1::coin::balance<LPToken<T0, T1>>(arg0)
    }
    
    fun mint_fee<T0, T1>(arg0: u64, arg1: u64, arg2: &mut TokenPairMetadata<T0, T1>) : u64 {
        let v0 = 0;
        if (arg2.k_last != 0) {
            let v1 = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::math::sqrt((arg0 as u128) * (arg1 as u128));
            let v2 = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::math::sqrt(arg2.k_last);
            if (v1 > v2) {
                let v3 = (total_lp_supply<T0, T1>() * (v1 - v2) * 8 / (v2 * 17 + v1 * 8)) as u64;
                v0 = v3;
                if (v3 > 0) {
                    0x1::coin::merge<LPToken<T0, T1>>(&mut arg2.fee_amount, mint_lp<T0, T1>(v3, &arg2.mint_cap));
                };
            };
        };
        v0
    }
    
    fun mint_lp<T0, T1>(arg0: u64, arg1: &0x1::coin::MintCapability<LPToken<T0, T1>>) : 0x1::coin::Coin<LPToken<T0, T1>> {
        0x1::coin::mint<LPToken<T0, T1>>(arg0, arg1)
    }
    
    fun mint_lp_to<T0, T1>(arg0: address, arg1: u64, arg2: &0x1::coin::MintCapability<LPToken<T0, T1>>) {
        0x1::coin::deposit<LPToken<T0, T1>>(arg0, 0x1::coin::mint<LPToken<T0, T1>>(arg1, arg2));
    }
    
    public fun register_lp<T0, T1>(arg0: &signer) {
        0x1::coin::register<LPToken<T0, T1>>(arg0);
    }
    
    public(friend) fun remove_liquidity<T0, T1>(arg0: &signer, arg1: u64) : (u64, u64) acquires PairEventHolder, TokenPairMetadata, TokenPairReserve {
        let (v0, v1, v2) = remove_liquidity_direct<T0, T1>(0x1::coin::withdraw<LPToken<T0, T1>>(arg0, arg1));
        let v3 = v1;
        let v4 = v0;
        let v5 = 0x1::coin::value<T0>(&v4);
        let v6 = 0x1::coin::value<T1>(&v3);
        check_or_register_coin_store<T0>(arg0);
        check_or_register_coin_store<T1>(arg0);
        let v7 = 0x1::signer::address_of(arg0);
        0x1::coin::deposit<T0>(v7, v4);
        0x1::coin::deposit<T1>(v7, v3);
        let v8 = RemoveLiquidityEvent<T0, T1>{
            user       : v7, 
            liquidity  : arg1, 
            amount_x   : v5, 
            amount_y   : v6, 
            fee_amount : v2 as u64,
        };
        0x1::event::emit_event<RemoveLiquidityEvent<T0, T1>>(&mut borrow_global_mut<PairEventHolder<T0, T1>>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa).remove_liquidity, v8);
        (v5, v6)
    }
    
    fun remove_liquidity_direct<T0, T1>(arg0: 0x1::coin::Coin<LPToken<T0, T1>>) : (0x1::coin::Coin<T0>, 0x1::coin::Coin<T1>, u64) acquires TokenPairMetadata, TokenPairReserve {
        burn<T0, T1>(arg0)
    }
    
    public entry fun set_admin(arg0: &signer, arg1: address) acquires SwapInfo {
        let v0 = borrow_global_mut<SwapInfo>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa);
        assert!(0x1::signer::address_of(arg0) == v0.admin, 17);
        v0.admin = arg1;
    }
    
    public entry fun set_fee_to(arg0: &signer, arg1: address) acquires SwapInfo {
        let v0 = borrow_global_mut<SwapInfo>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa);
        assert!(0x1::signer::address_of(arg0) == v0.admin, 17);
        v0.fee_to = arg1;
    }
    
    public(friend) fun swap_exact_x_to_y<T0, T1>(arg0: &signer, arg1: u64, arg2: address) : u64 acquires TokenPairMetadata, TokenPairReserve {
        let (v0, v1) = swap_exact_x_to_y_direct<T0, T1>(0x1::coin::withdraw<T0>(arg0, arg1));
        let v2 = v1;
        check_or_register_coin_store<T1>(arg0);
        0x1::coin::destroy_zero<T0>(v0);
        0x1::coin::deposit<T1>(arg2, v2);
        0x1::coin::value<T1>(&v2)
    }
    
    public(friend) fun swap_exact_x_to_y_direct<T0, T1>(arg0: 0x1::coin::Coin<T0>) : (0x1::coin::Coin<T0>, 0x1::coin::Coin<T1>) acquires TokenPairMetadata, TokenPairReserve {
        deposit_x<T0, T1>(arg0);
        let (v0, v1, _) = token_reserves<T0, T1>();
        let (v3, v4) = swap<T0, T1>(0, 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_out(0x1::coin::value<T0>(&arg0), v0, v1));
        let v5 = v3;
        assert!(0x1::coin::value<T0>(&v5) == 0, 13);
        (v5, v4)
    }
    
    public(friend) fun swap_exact_y_to_x<T0, T1>(arg0: &signer, arg1: u64, arg2: address) : u64 acquires TokenPairMetadata, TokenPairReserve {
        let (v0, v1) = swap_exact_y_to_x_direct<T0, T1>(0x1::coin::withdraw<T1>(arg0, arg1));
        let v2 = v0;
        check_or_register_coin_store<T0>(arg0);
        0x1::coin::deposit<T0>(arg2, v2);
        0x1::coin::destroy_zero<T1>(v1);
        0x1::coin::value<T0>(&v2)
    }
    
    public(friend) fun swap_exact_y_to_x_direct<T0, T1>(arg0: 0x1::coin::Coin<T1>) : (0x1::coin::Coin<T0>, 0x1::coin::Coin<T1>) acquires TokenPairMetadata, TokenPairReserve {
        deposit_y<T0, T1>(arg0);
        let (v0, v1, _) = token_reserves<T0, T1>();
        let (v3, v4) = swap<T0, T1>(0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_out(0x1::coin::value<T1>(&arg0), v1, v0), 0);
        let v5 = v4;
        assert!(0x1::coin::value<T1>(&v5) == 0, 13);
        (v3, v5)
    }
    
    public(friend) fun swap_x_to_exact_y<T0, T1>(arg0: &signer, arg1: u64, arg2: u64, arg3: address) : u64 acquires TokenPairMetadata, TokenPairReserve {
        let (v0, v1) = swap_x_to_exact_y_direct<T0, T1>(0x1::coin::withdraw<T0>(arg0, arg1), arg2);
        check_or_register_coin_store<T1>(arg0);
        0x1::coin::destroy_zero<T0>(v0);
        0x1::coin::deposit<T1>(arg3, v1);
        arg1
    }
    
    public(friend) fun swap_x_to_exact_y_direct<T0, T1>(arg0: 0x1::coin::Coin<T0>, arg1: u64) : (0x1::coin::Coin<T0>, 0x1::coin::Coin<T1>) acquires TokenPairMetadata, TokenPairReserve {
        deposit_x<T0, T1>(arg0);
        let (v0, v1) = swap<T0, T1>(0, arg1);
        let v2 = v0;
        assert!(0x1::coin::value<T0>(&v2) == 0, 13);
        (v2, v1)
    }
    
    public(friend) fun swap_y_to_exact_x<T0, T1>(arg0: &signer, arg1: u64, arg2: u64, arg3: address) : u64 acquires TokenPairMetadata, TokenPairReserve {
        let (v0, v1) = swap_y_to_exact_x_direct<T0, T1>(0x1::coin::withdraw<T1>(arg0, arg1), arg2);
        check_or_register_coin_store<T0>(arg0);
        0x1::coin::deposit<T0>(arg3, v0);
        0x1::coin::destroy_zero<T1>(v1);
        arg1
    }
    
    public(friend) fun swap_y_to_exact_x_direct<T0, T1>(arg0: 0x1::coin::Coin<T1>, arg1: u64) : (0x1::coin::Coin<T0>, 0x1::coin::Coin<T1>) acquires TokenPairMetadata, TokenPairReserve {
        deposit_y<T0, T1>(arg0);
        let (v0, v1) = swap<T0, T1>(arg1, 0);
        let v2 = v1;
        assert!(0x1::coin::value<T1>(&v2) == 0, 13);
        (v0, v2)
    }
    
    public fun token_balances<T0, T1>() : (u64, u64) acquires TokenPairMetadata {
        let v0 = borrow_global<TokenPairMetadata<T0, T1>>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa);
        (0x1::coin::value<T0>(&v0.balance_x), 0x1::coin::value<T1>(&v0.balance_y))
    }
    
    public fun token_reserves<T0, T1>() : (u64, u64, u64) acquires TokenPairReserve {
        let v0 = borrow_global<TokenPairReserve<T0, T1>>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa);
        (v0.reserve_x, v0.reserve_y, v0.block_timestamp_last)
    }
    
    public fun total_lp_supply<T0, T1>() : u128 {
        let v0 = 0x1::coin::supply<LPToken<T0, T1>>();
        0x1::option::get_with_default<u128>(&v0, 0)
    }
    
    public entry fun upgrade_swap(arg0: &signer, arg1: vector<u8>, arg2: vector<vector<u8>>) acquires SwapInfo {
        let v0 = borrow_global<SwapInfo>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa);
        assert!(0x1::signer::address_of(arg0) == v0.admin, 17);
        let v1 = 0x1::account::create_signer_with_capability(&v0.signer_cap);
        0x1::code::publish_package_txn(&v1, arg1, arg2);
    }
    
    public entry fun withdraw_fee<T0, T1>(arg0: &signer) acquires SwapInfo, TokenPairMetadata {
        let v0 = 0x1::signer::address_of(arg0);
        assert!(v0 == borrow_global<SwapInfo>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa).fee_to, 18);
        if (0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T0, T1>()) {
            let v1 = borrow_global_mut<TokenPairMetadata<T0, T1>>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa);
            assert!(0x1::coin::value<LPToken<T0, T1>>(&v1.fee_amount) > 0, 21);
            check_or_register_coin_store<LPToken<T0, T1>>(arg0);
            0x1::coin::deposit<LPToken<T0, T1>>(v0, 0x1::coin::extract_all<LPToken<T0, T1>>(&mut v1.fee_amount));
        } else {
            let v2 = borrow_global_mut<TokenPairMetadata<T1, T0>>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa);
            assert!(0x1::coin::value<LPToken<T1, T0>>(&v2.fee_amount) > 0, 21);
            check_or_register_coin_store<LPToken<T1, T0>>(arg0);
            0x1::coin::deposit<LPToken<T1, T0>>(v0, 0x1::coin::extract_all<LPToken<T1, T0>>(&mut v2.fee_amount));
        };
    }
    
    public entry fun withdraw_fee_noauth<T0, T1>() acquires SwapInfo, TokenPairMetadata {
        if (0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T0, T1>()) {
            let v0 = borrow_global_mut<TokenPairMetadata<T0, T1>>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa);
            assert!(0x1::coin::value<LPToken<T0, T1>>(&v0.fee_amount) > 0, 21);
            0x1::coin::deposit<LPToken<T0, T1>>(borrow_global<SwapInfo>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa).fee_to, 0x1::coin::extract_all<LPToken<T0, T1>>(&mut v0.fee_amount));
        } else {
            let v1 = borrow_global_mut<TokenPairMetadata<T1, T0>>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa);
            assert!(0x1::coin::value<LPToken<T1, T0>>(&v1.fee_amount) > 0, 21);
            0x1::coin::deposit<LPToken<T1, T0>>(borrow_global<SwapInfo>(@0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa).fee_to, 0x1::coin::extract_all<LPToken<T1, T0>>(&mut v1.fee_amount));
        };
    }
    
    // decompiled from Move bytecode v6
}

