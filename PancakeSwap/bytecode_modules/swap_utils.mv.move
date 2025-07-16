module 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap_utils {
    fun compare_struct<T0, T1>() : u8 {
        let v0 = get_token_info<T0>();
        let v1 = get_token_info<T1>();
        let v2 = 0x1::comparator::compare_u8_vector(v0, v1);
        if (0x1::comparator::is_greater_than(&v2)) {
            2
        } else {
            let v4 = 0x1::comparator::compare_u8_vector(v0, v1);
            let v5 = if (0x1::comparator::is_equal(&v4)) {
                0
            } else {
                1
            };
            v5
        }
    }
    
    public fun get_amount_in(arg0: u64, arg1: u64, arg2: u64) : u64 {
        assert!(arg0 > 0, 3);
        assert!(arg1 > 0 && arg2 > 0, 1);
        (((arg1 as u128) * (arg0 as u128) * 10000 / ((arg2 as u128) - (arg0 as u128)) * 9975) as u64) + 1
    }
    
    public fun get_amount_out(arg0: u64, arg1: u64, arg2: u64) : u64 {
        assert!(arg0 > 0, 0);
        assert!(arg1 > 0 && arg2 > 0, 1);
        let v0 = (arg0 as u128) * 9975;
        (v0 * (arg2 as u128) / ((arg1 as u128) * 10000 + v0)) as u64
    }
    
    public fun get_equal_enum() : u8 {
        0
    }
    
    public fun get_greater_enum() : u8 {
        2
    }
    
    public fun get_smaller_enum() : u8 {
        1
    }
    
    public fun get_token_info<T0>() : vector<u8> {
        let v0 = 0x1::type_info::type_name<T0>();
        *0x1::string::bytes(&v0)
    }
    
    public fun quote(arg0: u64, arg1: u64, arg2: u64) : u64 {
        assert!(arg0 > 0, 2);
        assert!(arg1 > 0 && arg2 > 0, 1);
        ((arg0 as u128) * (arg2 as u128) / (arg1 as u128)) as u64
    }
    
    public fun sort_token_type<T0, T1>() : bool {
        let v0 = compare_struct<T0, T1>();
        assert!(v0 != get_equal_enum(), 4);
        v0 == get_smaller_enum()
    }
    
    // decompiled from Move bytecode v6
}

