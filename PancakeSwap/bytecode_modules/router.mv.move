module 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::router {
    public entry fun add_liquidity<T0, T1>(arg0: &signer, arg1: u64, arg2: u64, arg3: u64, arg4: u64) {
        let v0 = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::is_pair_created<T0, T1>() || 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::is_pair_created<T1, T0>();
        if (!v0) {
            create_pair<T0, T1>(arg0);
        };
        if (0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T0, T1>()) {
            let (v1, v2, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::add_liquidity<T0, T1>(arg0, arg1, arg2);
            assert!(v1 >= arg3, 2);
            assert!(v2 >= arg4, 3);
        } else {
            let (v4, v5, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::add_liquidity<T1, T0>(arg0, arg2, arg1);
            assert!(v5 >= arg3, 2);
            assert!(v4 >= arg4, 3);
        };
    }
    
    public entry fun create_pair<T0, T1>(arg0: &signer) {
        if (0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T0, T1>()) {
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::create_pair<T0, T1>(arg0);
        } else {
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::create_pair<T1, T0>(arg0);
        };
    }
    
    public entry fun register_lp<T0, T1>(arg0: &signer) {
        0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::register_lp<T0, T1>(arg0);
    }
    
    public entry fun remove_liquidity<T0, T1>(arg0: &signer, arg1: u64, arg2: u64, arg3: u64) {
        is_pair_created_internal<T0, T1>();
        if (0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T0, T1>()) {
            let (v0, v1) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::remove_liquidity<T0, T1>(arg0, arg1);
            assert!(v0 >= arg2, 2);
            assert!(v1 >= arg3, 3);
        } else {
            let (v2, v3) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::remove_liquidity<T1, T0>(arg0, arg1);
            assert!(v3 >= arg2, 2);
            assert!(v2 >= arg3, 3);
        };
    }
    
    public fun get_amount_in<T0, T1>(arg0: u64) : u64 {
        is_pair_created_internal<T0, T1>();
        get_amount_in_internal<T0, T1>(0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T0, T1>(), arg0)
    }
    
    fun add_swap_event_internal<T0, T1>(arg0: &signer, arg1: u64, arg2: u64, arg3: u64, arg4: u64) {
        add_swap_event_with_address_internal<T0, T1>(0x1::signer::address_of(arg0), arg1, arg2, arg3, arg4);
    }
    
    fun add_swap_event_with_address_internal<T0, T1>(arg0: address, arg1: u64, arg2: u64, arg3: u64, arg4: u64) {
        if (0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T0, T1>()) {
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::add_swap_event_with_address<T0, T1>(arg0, arg1, arg2, arg3, arg4);
        } else {
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::add_swap_event_with_address<T1, T0>(arg0, arg2, arg1, arg4, arg3);
        };
    }
    
    fun get_amount_in_internal<T0, T1>(arg0: bool, arg1: u64) : u64 {
        if (arg0) {
            let (v1, v2, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::token_reserves<T0, T1>();
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_in(arg1, v1, v2)
        } else {
            let (v4, v5, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::token_reserves<T1, T0>();
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_in(arg1, v5, v4)
        }
    }
    
    fun get_intermediate_output<T0, T1>(arg0: bool, arg1: 0x1::coin::Coin<T0>) : 0x1::coin::Coin<T1> {
        if (arg0) {
            let (v1, v2) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::swap_exact_x_to_y_direct<T0, T1>(arg1);
            0x1::coin::destroy_zero<T0>(v1);
            v2
        } else {
            let (v3, v4) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::swap_exact_y_to_x_direct<T1, T0>(arg1);
            0x1::coin::destroy_zero<T0>(v4);
            v3
        }
    }
    
    fun get_intermediate_output_x_to_exact_y<T0, T1>(arg0: bool, arg1: 0x1::coin::Coin<T0>, arg2: u64) : 0x1::coin::Coin<T1> {
        if (arg0) {
            let (v1, v2) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::swap_x_to_exact_y_direct<T0, T1>(arg1, arg2);
            0x1::coin::destroy_zero<T0>(v1);
            v2
        } else {
            let (v3, v4) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::swap_y_to_exact_x_direct<T1, T0>(arg1, arg2);
            0x1::coin::destroy_zero<T0>(v4);
            v3
        }
    }
    
    fun is_pair_created_internal<T0, T1>() {
        assert!(0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::is_pair_created<T0, T1>() || 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::is_pair_created<T1, T0>(), 4);
    }
    
    public entry fun register_token<T0>(arg0: &signer) {
        0x1::coin::register<T0>(arg0);
    }
    
    public entry fun swap_exact_input<T0, T1>(arg0: &signer, arg1: u64, arg2: u64) {
        is_pair_created_internal<T0, T1>();
        let v0 = if (0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T0, T1>()) {
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::swap_exact_x_to_y<T0, T1>(arg0, arg1, 0x1::signer::address_of(arg0))
        } else {
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::swap_exact_y_to_x<T1, T0>(arg0, arg1, 0x1::signer::address_of(arg0))
        };
        assert!(v0 >= arg2, 0);
        add_swap_event_internal<T0, T1>(arg0, arg1, 0, 0, v0);
    }
    
    fun swap_exact_input_double_internal<T0, T1, T2>(arg0: &signer, arg1: bool, arg2: bool, arg3: u64, arg4: u64) : u64 {
        let v0 = get_intermediate_output<T0, T1>(arg1, 0x1::coin::withdraw<T0>(arg0, arg3));
        let v1 = 0x1::coin::value<T1>(&v0);
        let v2 = get_intermediate_output<T1, T2>(arg2, v0);
        let v3 = 0x1::coin::value<T2>(&v2);
        assert!(v3 >= arg4, 0);
        0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::check_or_register_coin_store<T2>(arg0);
        0x1::coin::deposit<T2>(0x1::signer::address_of(arg0), v2);
        add_swap_event_internal<T0, T1>(arg0, arg3, 0, 0, v1);
        add_swap_event_internal<T1, T2>(arg0, v1, 0, 0, v3);
        v3
    }
    
    public entry fun swap_exact_input_doublehop<T0, T1, T2>(arg0: &signer, arg1: u64, arg2: u64) {
        is_pair_created_internal<T0, T1>();
        is_pair_created_internal<T1, T2>();
        swap_exact_input_double_internal<T0, T1, T2>(arg0, 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T0, T1>(), 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T1, T2>(), arg1, arg2);
    }
    
    fun swap_exact_input_quadruple_internal<T0, T1, T2, T3, T4>(arg0: &signer, arg1: bool, arg2: bool, arg3: bool, arg4: bool, arg5: u64, arg6: u64) : u64 {
        let v0 = get_intermediate_output<T0, T1>(arg1, 0x1::coin::withdraw<T0>(arg0, arg5));
        let v1 = 0x1::coin::value<T1>(&v0);
        let v2 = get_intermediate_output<T1, T2>(arg2, v0);
        let v3 = 0x1::coin::value<T2>(&v2);
        let v4 = get_intermediate_output<T2, T3>(arg3, v2);
        let v5 = 0x1::coin::value<T3>(&v4);
        let v6 = get_intermediate_output<T3, T4>(arg4, v4);
        let v7 = 0x1::coin::value<T4>(&v6);
        assert!(v7 >= arg6, 0);
        0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::check_or_register_coin_store<T4>(arg0);
        0x1::coin::deposit<T4>(0x1::signer::address_of(arg0), v6);
        add_swap_event_internal<T0, T1>(arg0, arg5, 0, 0, v1);
        add_swap_event_internal<T1, T2>(arg0, v1, 0, 0, v3);
        add_swap_event_internal<T2, T3>(arg0, v3, 0, 0, v5);
        add_swap_event_internal<T3, T4>(arg0, v5, 0, 0, v7);
        v7
    }
    
    public entry fun swap_exact_input_quadruplehop<T0, T1, T2, T3, T4>(arg0: &signer, arg1: u64, arg2: u64) {
        is_pair_created_internal<T0, T1>();
        is_pair_created_internal<T1, T2>();
        is_pair_created_internal<T2, T3>();
        is_pair_created_internal<T3, T4>();
        swap_exact_input_quadruple_internal<T0, T1, T2, T3, T4>(arg0, 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T0, T1>(), 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T1, T2>(), 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T2, T3>(), 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T3, T4>(), arg1, arg2);
    }
    
    fun swap_exact_input_triple_internal<T0, T1, T2, T3>(arg0: &signer, arg1: bool, arg2: bool, arg3: bool, arg4: u64, arg5: u64) : u64 {
        let v0 = get_intermediate_output<T0, T1>(arg1, 0x1::coin::withdraw<T0>(arg0, arg4));
        let v1 = 0x1::coin::value<T1>(&v0);
        let v2 = get_intermediate_output<T1, T2>(arg2, v0);
        let v3 = 0x1::coin::value<T2>(&v2);
        let v4 = get_intermediate_output<T2, T3>(arg3, v2);
        let v5 = 0x1::coin::value<T3>(&v4);
        assert!(v5 >= arg5, 0);
        0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::check_or_register_coin_store<T3>(arg0);
        0x1::coin::deposit<T3>(0x1::signer::address_of(arg0), v4);
        add_swap_event_internal<T0, T1>(arg0, arg4, 0, 0, v1);
        add_swap_event_internal<T1, T2>(arg0, v1, 0, 0, v3);
        add_swap_event_internal<T2, T3>(arg0, v3, 0, 0, v5);
        v5
    }
    
    public entry fun swap_exact_input_triplehop<T0, T1, T2, T3>(arg0: &signer, arg1: u64, arg2: u64) {
        is_pair_created_internal<T0, T1>();
        is_pair_created_internal<T1, T2>();
        is_pair_created_internal<T2, T3>();
        swap_exact_input_triple_internal<T0, T1, T2, T3>(arg0, 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T0, T1>(), 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T1, T2>(), 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T2, T3>(), arg1, arg2);
    }
    
    public entry fun swap_exact_output<T0, T1>(arg0: &signer, arg1: u64, arg2: u64) {
        is_pair_created_internal<T0, T1>();
        let v0 = if (0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T0, T1>()) {
            let (v1, v2, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::token_reserves<T0, T1>();
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::swap_x_to_exact_y<T0, T1>(arg0, 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_in(arg1, v1, v2), arg1, 0x1::signer::address_of(arg0))
        } else {
            let (v4, v5, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::token_reserves<T1, T0>();
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::swap_y_to_exact_x<T1, T0>(arg0, 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_in(arg1, v5, v4), arg1, 0x1::signer::address_of(arg0))
        };
        assert!(v0 <= arg2, 1);
        add_swap_event_internal<T0, T1>(arg0, v0, 0, 0, arg1);
    }
    
    fun swap_exact_output_double_internal<T0, T1, T2>(arg0: &signer, arg1: bool, arg2: bool, arg3: u64, arg4: u64) : u64 {
        let v0 = if (arg2) {
            let (v1, v2, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::token_reserves<T1, T2>();
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_in(arg4, v1, v2)
        } else {
            let (v4, v5, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::token_reserves<T2, T1>();
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_in(arg4, v5, v4)
        };
        let v7 = if (arg1) {
            let (v8, v9, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::token_reserves<T0, T1>();
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_in(v0, v8, v9)
        } else {
            let (v11, v12, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::token_reserves<T1, T0>();
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_in(v0, v12, v11)
        };
        assert!(v7 <= arg3, 1);
        let v14 = get_intermediate_output_x_to_exact_y<T1, T2>(arg2, get_intermediate_output_x_to_exact_y<T0, T1>(arg1, 0x1::coin::withdraw<T0>(arg0, v7), v0), arg4);
        let v15 = 0x1::coin::value<T2>(&v14);
        0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::check_or_register_coin_store<T2>(arg0);
        0x1::coin::deposit<T2>(0x1::signer::address_of(arg0), v14);
        add_swap_event_internal<T0, T1>(arg0, v7, 0, 0, v0);
        add_swap_event_internal<T1, T2>(arg0, v0, 0, 0, v15);
        v15
    }
    
    public entry fun swap_exact_output_doublehop<T0, T1, T2>(arg0: &signer, arg1: u64, arg2: u64) {
        is_pair_created_internal<T0, T1>();
        is_pair_created_internal<T1, T2>();
        swap_exact_output_double_internal<T0, T1, T2>(arg0, 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T0, T1>(), 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T1, T2>(), arg2, arg1);
    }
    
    fun swap_exact_output_quadruple_internal<T0, T1, T2, T3, T4>(arg0: &signer, arg1: bool, arg2: bool, arg3: bool, arg4: bool, arg5: u64, arg6: u64) : u64 {
        let v0 = if (arg4) {
            let (v1, v2, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::token_reserves<T3, T4>();
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_in(arg6, v1, v2)
        } else {
            let (v4, v5, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::token_reserves<T4, T3>();
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_in(arg6, v5, v4)
        };
        let v7 = if (arg3) {
            let (v8, v9, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::token_reserves<T2, T3>();
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_in(v0, v8, v9)
        } else {
            let (v11, v12, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::token_reserves<T3, T2>();
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_in(v0, v12, v11)
        };
        let v14 = if (arg2) {
            let (v15, v16, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::token_reserves<T1, T2>();
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_in(v7, v15, v16)
        } else {
            let (v18, v19, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::token_reserves<T2, T1>();
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_in(v7, v19, v18)
        };
        let v21 = if (arg1) {
            let (v22, v23, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::token_reserves<T0, T1>();
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_in(v14, v22, v23)
        } else {
            let (v25, v26, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::token_reserves<T1, T0>();
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_in(v14, v26, v25)
        };
        assert!(v21 <= arg5, 1);
        let v28 = get_intermediate_output_x_to_exact_y<T3, T4>(arg4, get_intermediate_output_x_to_exact_y<T2, T3>(arg3, get_intermediate_output_x_to_exact_y<T1, T2>(arg2, get_intermediate_output_x_to_exact_y<T0, T1>(arg1, 0x1::coin::withdraw<T0>(arg0, v21), v14), v7), v0), arg6);
        let v29 = 0x1::coin::value<T4>(&v28);
        0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::check_or_register_coin_store<T4>(arg0);
        0x1::coin::deposit<T4>(0x1::signer::address_of(arg0), v28);
        add_swap_event_internal<T0, T1>(arg0, v21, 0, 0, v14);
        add_swap_event_internal<T1, T2>(arg0, v14, 0, 0, v7);
        add_swap_event_internal<T2, T3>(arg0, v7, 0, 0, v0);
        add_swap_event_internal<T3, T4>(arg0, v0, 0, 0, v29);
        v29
    }
    
    public entry fun swap_exact_output_quadruplehop<T0, T1, T2, T3, T4>(arg0: &signer, arg1: u64, arg2: u64) {
        is_pair_created_internal<T0, T1>();
        is_pair_created_internal<T1, T2>();
        is_pair_created_internal<T2, T3>();
        is_pair_created_internal<T3, T4>();
        swap_exact_output_quadruple_internal<T0, T1, T2, T3, T4>(arg0, 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T0, T1>(), 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T1, T2>(), 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T2, T3>(), 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T3, T4>(), arg2, arg1);
    }
    
    fun swap_exact_output_triple_internal<T0, T1, T2, T3>(arg0: &signer, arg1: bool, arg2: bool, arg3: bool, arg4: u64, arg5: u64) : u64 {
        let v0 = if (arg3) {
            let (v1, v2, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::token_reserves<T2, T3>();
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_in(arg5, v1, v2)
        } else {
            let (v4, v5, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::token_reserves<T3, T2>();
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_in(arg5, v5, v4)
        };
        let v7 = if (arg2) {
            let (v8, v9, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::token_reserves<T1, T2>();
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_in(v0, v8, v9)
        } else {
            let (v11, v12, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::token_reserves<T2, T1>();
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_in(v0, v12, v11)
        };
        let v14 = if (arg1) {
            let (v15, v16, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::token_reserves<T0, T1>();
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_in(v7, v15, v16)
        } else {
            let (v18, v19, _) = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::token_reserves<T1, T0>();
            0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::get_amount_in(v7, v19, v18)
        };
        assert!(v14 <= arg4, 1);
        let v21 = get_intermediate_output_x_to_exact_y<T2, T3>(arg3, get_intermediate_output_x_to_exact_y<T1, T2>(arg2, get_intermediate_output_x_to_exact_y<T0, T1>(arg1, 0x1::coin::withdraw<T0>(arg0, v14), v7), v0), arg5);
        let v22 = 0x1::coin::value<T3>(&v21);
        0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap::check_or_register_coin_store<T3>(arg0);
        0x1::coin::deposit<T3>(0x1::signer::address_of(arg0), v21);
        add_swap_event_internal<T0, T1>(arg0, v14, 0, 0, v7);
        add_swap_event_internal<T1, T2>(arg0, v7, 0, 0, v0);
        add_swap_event_internal<T2, T3>(arg0, v0, 0, 0, v22);
        v22
    }
    
    public entry fun swap_exact_output_triplehop<T0, T1, T2, T3>(arg0: &signer, arg1: u64, arg2: u64) {
        is_pair_created_internal<T0, T1>();
        is_pair_created_internal<T1, T2>();
        is_pair_created_internal<T2, T3>();
        swap_exact_output_triple_internal<T0, T1, T2, T3>(arg0, 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T0, T1>(), 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T1, T2>(), 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T2, T3>(), arg2, arg1);
    }
    
    public fun swap_exact_x_to_y_direct_external<T0, T1>(arg0: 0x1::coin::Coin<T0>) : 0x1::coin::Coin<T1> {
        is_pair_created_internal<T0, T1>();
        let v0 = get_intermediate_output<T0, T1>(0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T0, T1>(), arg0);
        add_swap_event_with_address_internal<T0, T1>(@0x0, 0x1::coin::value<T0>(&arg0), 0, 0, 0x1::coin::value<T1>(&v0));
        v0
    }
    
    public fun swap_x_to_exact_y_direct_external<T0, T1>(arg0: 0x1::coin::Coin<T0>, arg1: u64) : (0x1::coin::Coin<T0>, 0x1::coin::Coin<T1>) {
        is_pair_created_internal<T0, T1>();
        let v0 = 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils::sort_token_type<T0, T1>();
        let v1 = get_amount_in_internal<T0, T1>(v0, arg1);
        let v2 = 0x1::coin::value<T0>(&arg0);
        assert!(v2 >= v1, 2);
        add_swap_event_with_address_internal<T0, T1>(@0x0, v1, 0, 0, arg1);
        (0x1::coin::extract<T0>(&mut arg0, v2 - v1), get_intermediate_output_x_to_exact_y<T0, T1>(v0, arg0, arg1))
    }
    
    // decompiled from Move bytecode v6
}

