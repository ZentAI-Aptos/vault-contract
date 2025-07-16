module 0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::router {
    public fun initialize(arg0: &signer, arg1: address, arg2: address, arg3: address, arg4: u128, arg5: u128) {
        0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::pool::initialize(arg0, arg1, arg2, arg3, arg4, arg5);
    }
    
    public fun register_pool<T0, T1, T2>(arg0: &signer, arg1: u32, arg2: u128, arg3: u64, arg4: u64, arg5: u32, arg6: u32, arg7: u128, arg8: u32, arg9: u128) {
        0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::pool::register_pool<T0, T1, T2>(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9);
    }
    
    public fun add_liquidity<T0, T1, T2>(arg0: 0x1::coin::Coin<T0>, arg1: 0x1::coin::Coin<T1>, arg2: vector<u32>, arg3: u32, arg4: u32, arg5: vector<u64>, arg6: vector<u64>, arg7: u64, arg8: u64) : (vector<0x3::token::Token>, 0x1::coin::Coin<T0>, 0x1::coin::Coin<T1>) {
        let v0 = 0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::pool::get_active_bin_id<T0, T1, T2>();
        assert_active_bin_slippage(v0, arg3, arg4);
        let v1 = 0;
        if (v0 > arg3) {
            while (v1 < 0x1::vector::length<u32>(&arg2)) {
                let v2 = 0x1::vector::borrow_mut<u32>(&mut arg2, v1);
                *v2 = *v2 + v0 - arg3;
                assert!(*v2 < 16777216, 106);
                v1 = v1 + 1;
            };
        } else {
            let v3 = arg3 - v0;
            while (v1 < 0x1::vector::length<u32>(&arg2)) {
                let v4 = 0x1::vector::borrow_mut<u32>(&mut arg2, v1);
                assert!(*v4 >= v3, 106);
                *v4 = *v4 - v3;
                v1 = v1 + 1;
            };
        };
        add_liquidity_inner<T0, T1, T2>(arg0, arg1, arg2, arg5, arg6, arg7, arg8)
    }
    
    fun add_liquidity_inner<T0, T1, T2>(arg0: 0x1::coin::Coin<T0>, arg1: 0x1::coin::Coin<T1>, arg2: vector<u32>, arg3: vector<u64>, arg4: vector<u64>, arg5: u64, arg6: u64) : (vector<0x3::token::Token>, 0x1::coin::Coin<T0>, 0x1::coin::Coin<T1>) {
        let (v0, v1, v2) = 0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::pool::mint<T0, T1, T2>(arg0, arg1, arg2, arg3, arg4);
        let v3 = v2;
        let v4 = v1;
        assert!(0x1::coin::value<T0>(&arg0) - 0x1::coin::value<T0>(&v4) >= arg5, 107);
        assert!(0x1::coin::value<T1>(&arg1) - 0x1::coin::value<T1>(&v3) >= arg6, 107);
        (v0, v4, v3)
    }
    
    fun assert_active_bin_slippage(arg0: u32, arg1: u32, arg2: u32) {
        assert!(arg1 < 16777216 && arg2 < 16777216, 103);
        assert!(arg0 <= arg1 + arg2 && arg1 <= arg0 + arg2, 104);
    }
    
    public fun get_amounts_out_from_shares_burn(arg0: u64, arg1: u64, arg2: u64, arg3: u64) : (u64, u64) {
        0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::bin_helper::get_amounts_out_from_shares(arg0, arg1, arg2, arg3)
    }
    
    public fun get_price_from_bin_id(arg0: u32, arg1: u32) : u128 {
        0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::bin_helper::get_price_from_id_fp64(arg0, arg1)
    }
    
    public fun get_prices_from_bin_ids(arg0: vector<u32>, arg1: u32) : vector<u128> {
        let v0 = 0x1::vector::empty<u128>();
        let v1 = 0;
        while (v1 < 0x1::vector::length<u32>(&arg0)) {
            0x1::vector::push_back<u128>(&mut v0, 0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::bin_helper::get_price_from_id_fp64(*0x1::vector::borrow<u32>(&arg0, v1), arg1));
            v1 = v1 + 1;
        };
        v0
    }
    
    public fun get_shares_and_effective_amounts_in(arg0: u64, arg1: u64, arg2: u64, arg3: u64, arg4: u128, arg5: u64) : (u64, u64, u64) {
        if (arg2 == 0 && arg3 == 0) {
            return (0, arg2, arg3)
        };
        let v0 = 0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::bin_helper::get_liquidity_fp64(arg2, arg3, arg4);
        let v1 = 0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::bin_helper::get_liquidity_fp64(arg0, arg1, arg4);
        if (arg5 == 0 || v0 == 0 || v1 == 0) {
            return ((v0 >> 64) as u64, 0, 0)
        };
        let v2 = (((v0 as u256) * ((arg5 as u128) as u256) / (v1 as u256)) as u128) as u64;
        let (v3, v4) = 0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::bin_helper::compute_effective_amounts_in(v0, 0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::fp64_math::mul_div_round_up(v2 as u128, v1, arg5 as u128), arg2, arg3, arg4);
        (v2, arg2 - v3, arg3 - v4)
    }
    
    public fun remove_liquidity<T0, T1, T2>(arg0: vector<0x3::token::Token>, arg1: u64, arg2: u64) : (0x1::coin::Coin<T0>, 0x1::coin::Coin<T1>) {
        let (v0, v1) = 0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::pool::burn<T0, T1, T2>(arg0);
        let v2 = v1;
        let v3 = v0;
        assert!(0x1::coin::value<T0>(&v3) >= arg1 && 0x1::coin::value<T1>(&v2) >= arg2, 105);
        (v3, v2)
    }
    
    public fun swap_exact_x_for_y<T0, T1, T2>(arg0: 0x1::coin::Coin<T0>, arg1: u64) : 0x1::coin::Coin<T1> {
        let v0 = 0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::pool::swap_x_for_y<T0, T1, T2>(arg0);
        assert!(0x1::coin::value<T1>(&v0) >= arg1, 100);
        v0
    }
    
    public fun swap_exact_y_for_x<T0, T1, T2>(arg0: 0x1::coin::Coin<T1>, arg1: u64) : 0x1::coin::Coin<T0> {
        let v0 = 0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::pool::swap_y_for_x<T0, T1, T2>(arg0);
        assert!(0x1::coin::value<T0>(&v0) >= arg1, 100);
        v0
    }
    
    public fun swap_x_for_exact_y<T0, T1, T2>(arg0: 0x1::coin::Coin<T0>, arg1: u64) : (0x1::coin::Coin<T1>, 0x1::coin::Coin<T0>) {
        let (v0, v1, _) = 0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::pool::get_amount_in<T0, T1, T2>(arg1, false);
        assert!(v1 == 0, 101);
        let v3 = 0x1::coin::value<T0>(&arg0);
        assert!(v0 <= v3, 102);
        (0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::pool::swap_x_for_y<T0, T1, T2>(arg0), 0x1::coin::extract<T0>(&mut arg0, v3 - v0))
    }
    
    public fun swap_y_for_exact_x<T0, T1, T2>(arg0: 0x1::coin::Coin<T1>, arg1: u64) : (0x1::coin::Coin<T0>, 0x1::coin::Coin<T1>) {
        let (v0, v1, _) = 0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::pool::get_amount_in<T0, T1, T2>(arg1, true);
        assert!(v1 == 0, 101);
        let v3 = 0x1::coin::value<T1>(&arg0);
        assert!(v0 <= v3, 102);
        (0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::pool::swap_y_for_x<T0, T1, T2>(arg0), 0x1::coin::extract<T1>(&mut arg0, v3 - v0))
    }
    
    // decompiled from Move bytecode v6
}

