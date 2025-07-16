module 0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::entry {
    public entry fun add_liquidity<T0, T1, T2>(arg0: &signer, arg1: u64, arg2: u64, arg3: vector<u32>, arg4: u32, arg5: u32, arg6: vector<u64>, arg7: vector<u64>, arg8: u64, arg9: u64) {
        let (v0, v1, v2) = 0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::router::add_liquidity<T0, T1, T2>(0x1::coin::withdraw<T0>(arg0, arg1), 0x1::coin::withdraw<T1>(arg0, arg2), arg3, arg4, arg5, arg6, arg7, arg8, arg9);
        let v3 = v0;
        while (!0x1::vector::is_empty<0x3::token::Token>(&v3)) {
            0x3::token::deposit_token(arg0, 0x1::vector::pop_back<0x3::token::Token>(&mut v3));
        };
        0x1::vector::destroy_empty<0x3::token::Token>(v3);
        let v4 = 0x1::signer::address_of(arg0);
        0x1::coin::deposit<T0>(v4, v1);
        0x1::coin::deposit<T1>(v4, v2);
    }
    
    public entry fun initialize(arg0: &signer, arg1: address, arg2: address, arg3: address, arg4: u128, arg5: u128) {
        0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::router::initialize(arg0, arg1, arg2, arg3, arg4, arg5);
    }
    
    public entry fun remove_liquidity<T0, T1, T2>(arg0: &signer, arg1: vector<u32>, arg2: vector<u64>, arg3: u64, arg4: u64) {
        let v0 = 0x1::vector::empty<0x3::token::Token>();
        let v1 = 0;
        while (v1 < 0x1::vector::length<u32>(&arg1)) {
            let (_, _, v4) = 0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::pool::get_bin_fields<T0, T1, T2>(*0x1::vector::borrow<u32>(&arg1, v1));
            0x1::vector::push_back<0x3::token::Token>(&mut v0, 0x3::token::withdraw_token(arg0, 0x3::token::create_token_id(0x1::option::destroy_some<0x3::token::TokenDataId>(v4), 0), *0x1::vector::borrow<u64>(&arg2, v1)));
            v1 = v1 + 1;
        };
        let (v5, v6) = 0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::router::remove_liquidity<T0, T1, T2>(v0, arg3, arg4);
        let v7 = 0x1::signer::address_of(arg0);
        if (!0x1::coin::is_account_registered<T0>(v7)) {
            0x1::coin::register<T0>(arg0);
        };
        if (!0x1::coin::is_account_registered<T1>(v7)) {
            0x1::coin::register<T1>(arg0);
        };
        0x1::coin::deposit<T0>(v7, v5);
        0x1::coin::deposit<T1>(v7, v6);
    }
    
    public entry fun swap_exact_x_for_y<T0, T1, T2>(arg0: &signer, arg1: u64, arg2: u64) {
        let v0 = 0x1::signer::address_of(arg0);
        if (!0x1::coin::is_account_registered<T1>(v0)) {
            0x1::coin::register<T1>(arg0);
        };
        0x1::coin::deposit<T1>(v0, 0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::router::swap_exact_x_for_y<T0, T1, T2>(0x1::coin::withdraw<T0>(arg0, arg1), arg2));
    }
    
    public entry fun swap_exact_y_for_x<T0, T1, T2>(arg0: &signer, arg1: u64, arg2: u64) {
        let v0 = 0x1::signer::address_of(arg0);
        if (!0x1::coin::is_account_registered<T0>(v0)) {
            0x1::coin::register<T0>(arg0);
        };
        0x1::coin::deposit<T0>(v0, 0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::router::swap_exact_y_for_x<T0, T1, T2>(0x1::coin::withdraw<T1>(arg0, arg1), arg2));
    }
    
    public entry fun swap_x_for_exact_y<T0, T1, T2>(arg0: &signer, arg1: u64, arg2: u64) {
        let (v0, v1) = 0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::router::swap_x_for_exact_y<T0, T1, T2>(0x1::coin::withdraw<T0>(arg0, arg1), arg2);
        let v2 = 0x1::signer::address_of(arg0);
        if (!0x1::coin::is_account_registered<T1>(v2)) {
            0x1::coin::register<T1>(arg0);
        };
        0x1::coin::deposit<T0>(v2, v1);
        0x1::coin::deposit<T1>(v2, v0);
    }
    
    public entry fun swap_y_for_exact_x<T0, T1, T2>(arg0: &signer, arg1: u64, arg2: u64) {
        let (v0, v1) = 0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::router::swap_y_for_exact_x<T0, T1, T2>(0x1::coin::withdraw<T1>(arg0, arg1), arg2);
        let v2 = 0x1::signer::address_of(arg0);
        if (!0x1::coin::is_account_registered<T0>(v2)) {
            0x1::coin::register<T0>(arg0);
        };
        0x1::coin::deposit<T1>(v2, v1);
        0x1::coin::deposit<T0>(v2, v0);
    }
    
    public entry fun register_pool_with_custom_fee_params<T0, T1, T2>(arg0: &signer, arg1: u32, arg2: u128, arg3: u64, arg4: u64, arg5: u32, arg6: u32, arg7: u128, arg8: u32, arg9: u128) {
        0xc9ccc585c8e1455a5c0ae4e068897a47e7c16cf16f14e0655e3573c2bbc76d48::router::register_pool<T0, T1, T2>(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9);
    }
    
    // decompiled from Move bytecode v6
}

