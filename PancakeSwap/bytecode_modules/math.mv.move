module 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::math {
    public fun max_u64(arg0: u64, arg1: u64) : u64 {
        if (arg0 < arg1) {
            arg1
        } else {
            arg0
        }
    }
    
    public fun max(arg0: u128, arg1: u128) : u128 {
        if (arg0 < arg1) {
            arg1
        } else {
            arg0
        }
    }
    
    public fun min(arg0: u128, arg1: u128) : u128 {
        if (arg0 > arg1) {
            arg1
        } else {
            arg0
        }
    }
    
    public fun pow(arg0: u128, arg1: u8) : u128 {
        let v0 = 1;
        loop {
            if (arg1 & 1 == 1) {
                v0 = v0 * arg0;
            };
            let v1 = arg1 >> 1;
            arg1 = v1;
            arg0 = arg0 * arg0;
            if (v1 == 0) {
                break
            };
        };
        v0
    }
    
    public fun sqrt(arg0: u128) : u128 {
        if (arg0 < 4) {
            let v1 = if (arg0 == 0) {
                0
            } else {
                1
            };
            v1
        } else {
            let v2 = arg0;
            let v3 = arg0 / 2 + 1;
            while (v3 < v2) {
                v2 = v3;
                let v4 = arg0 / v3 + v3;
                v3 = v4 / 2;
            };
            v2
        }
    }
    
    // decompiled from Move bytecode v6
}

