module zentai_vault::shielded_vault {
    use std::signer;
    use std::vector;
    use std::hash;
    use std::string::{Self, String};
    use std::error;
    use std::option::{Self, Option};
    use std::table::{Self, Table};
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::account;
    use std::bcs;
    use aptos_std::ristretto255_bulletproofs as bulletproofs;
    // Add imports for RangeProof and Commitment
    use aptos_std::ristretto255_bulletproofs::RangeProof;
    use aptos_std::ristretto255_pedersen::{Self, Commitment as PedersenCommitment};
    use aptos_std::ristretto255_elgamal as elgamal;
    use aptos_std::ristretto255_pedersen as pedersen;
    use zentai_vault::vault_verifier;


    const E_VAULT_ALREADY_INITIALIZED: u64 = 1;
    const E_VAULT_NOT_INITIALIZED: u64 = 2;
    const E_INVALID_AMOUNT: u64 = 3;
    const E_MERKLE_TREE_IS_FULL: u64 = 4;
    const E_NULLIFIER_ALREADY_USED: u64 = 5;
    const E_INVALID_MERKLE_ROOT: u64 = 6;
    const E_INVALID_PROOF: u64 = 7;
    const E_INVALID_RECIPIENT: u64 = 8;
    const E_DESERIALIZATION_FAILED: u64 = 9;

    const MERKLE_TREE_DEPTH: u64 = 32;
    /// Domain separation tag for Bulletproofs, inspired by sample code.
    const BULLETPROOF_DST: vector<u8> = b"ZENTAI_SHIELDED_VAULT_V2";


    #[event]
    struct DepositEvent has drop, store {
        commitment_index: u64,
        commitment_point: vector<u8>,
        timestamp: u64,
    }

    #[event]
    struct WithdrawEvent has drop, store {
        recipient: address,
        amount: u64,
        nullifier_hash: vector<u8>,
    }
    
    struct Commitment has store {
        point: vector<u8>,
        ciphertext: vector<u8>,
    }

    struct MerkleTree has store {
        levels: vector<vector<vector<u8>>>,
        next_index: u64,
        roots: Table<vector<u8>, bool>,
    }

     struct PrivacyVault<phantom CoinType> has key {
        deposits: Coin<CoinType>,
        commitments: Table<u64, Commitment>,
        nullifiers: Table<vector<u8>, bool>,
        merkle_tree: MerkleTree,
    }


    /// Withdraws funds from the vault by spending an old commitment and creating a change commitment.
    /// Bulletproofs are used to validate the change commitment.
    public entry fun withdraw<CoinType>(
        account: &signer, // Đổi tên _account thành account để sử dụng
        // Các đầu vào công khai cho mạch ZK
        amount: u64,
        recipient: address,
        merkle_root: vector<u8>,
        nullifier_hash: vector<u8>,
        change_commitment_bytes: vector<u8>,
        // Dữ liệu phụ
        change_ciphertext_bytes: vector<u8>,
        // Bằng chứng và các thành phần của nó dưới dạng chuỗi byte
        proof_a_bytes: vector<u8>,
        proof_b_bytes: vector<u8>,
        proof_c_bytes: vector<u8>,
    ) acquires PrivacyVault {
        assert!(amount > 0, error::invalid_argument(E_INVALID_AMOUNT));
        let vault_addr = @zentai_vault;
        assert!(exists<PrivacyVault<CoinType>>(vault_addr), error::not_found(E_VAULT_NOT_INITIALIZED));
        let vault = borrow_global_mut<PrivacyVault<CoinType>>(vault_addr);

        // 1. Xác thực Merkle Root và Nullifier (logic nghiệp vụ)
        assert!(table::contains(&vault.merkle_tree.roots, merkle_root), error::invalid_argument(E_INVALID_MERKLE_ROOT));
        assert!(!table::contains(&vault.nullifiers, nullifier_hash), error::invalid_argument(E_NULLIFIER_ALREADY_USED));

        // 2. Chuẩn bị các đầu vào công khai cho verifier
        // Thứ tự phải TUYỆT ĐỐI chính xác với thứ tự trong mạch Circom
        let public_inputs_bytes = vector[
            bcs::to_bytes(&merkle_root),
            bcs::to_bytes(&nullifier_hash),
            bcs::to_bytes(&recipient),
            bcs::to_bytes(&amount),
            bcs::to_bytes(&change_commitment_bytes)
        ];

        // 3. GỌI HÀM XÁC MINH
        // Toàn bộ sự phức tạp của ZK-SNARK được gói gọn trong một lệnh gọi duy nhất!
        let is_proof_valid = vault_verifier::verify_withdraw_proof(
            account, // Truyền signer vào để bật native crypto
            &public_inputs_bytes,
            &proof_a_bytes,
            &proof_b_bytes,
            &proof_c_bytes,
        );
        assert!(is_proof_valid, error::permission_denied(E_INVALID_PROOF));

        // 4. Cập nhật trạng thái vault nếu bằng chứng hợp lệ
        let new_commitment = Commitment {
            point: change_commitment_bytes,
            ciphertext: change_ciphertext_bytes,
        };
        let new_commitment_index = vault.merkle_tree.next_index;
        table::add(&mut vault.commitments, new_commitment_index, new_commitment);
        merkle_insert(&mut vault.merkle_tree, change_commitment_bytes);
        
        table::add(&mut vault.nullifiers, nullifier_hash, true);
        let withdrawn_coins = coin::extract(&mut vault.deposits, amount);
        coin::deposit(recipient, withdrawn_coins);
    }
    
    // Cần cập nhật `initialize_vault` để gọi `vault_verifier::initialize`
    public entry fun initialize_vault<CoinType>(
        deployer: &signer,
        // Thêm các tham số VK để khởi tạo verifier
        vk_alpha_g1_bytes: vector<u8>,
        vk_beta_g2_bytes: vector<u8>,
        vk_gamma_g2_bytes: vector<u8>,
        vk_delta_g2_bytes: vector<u8>,
        vk_uvw_gamma_g1_bytes: vector<vector<u8>>,
    ) {
        let deployer_addr = signer::address_of(deployer);
        assert!(!exists<PrivacyVault<CoinType>>(deployer_addr), error::already_exists(E_VAULT_ALREADY_INITIALIZED));
        
        // Khởi tạo verifier với Khóa Xác Minh
        vault_verifier::initialize(
            deployer,
            vk_alpha_g1_bytes,
            vk_beta_g2_bytes,
            vk_gamma_g2_bytes,
            vk_delta_g2_bytes,
            vk_uvw_gamma_g1_bytes,
        );

        // Khởi tạo vault như cũ
        let levels = vector[];
        let i = 0;
        while (i <= MERKLE_TREE_DEPTH) {
            vector::push_back(&mut levels, vector[]);
            i = i + 1;
        };
        let tree = MerkleTree { levels, next_index: 0, roots: table::new() };
        let vault = PrivacyVault<CoinType> {
            deposits: coin::zero<CoinType>(),
            commitments: table::new(),
            nullifiers: table::new(),
            merkle_tree: tree,
        };
        move_to(deployer, vault);
    }

    public entry fun deposit<CoinType>(
        sender: &signer,
        amount: u64,
        commitment_point: vector<u8>,
        ciphertext: vector<u8>,
    ) acquires PrivacyVault {
        assert!(amount > 0, error::invalid_argument(E_INVALID_AMOUNT));
        let vault_addr = @zentai_vault;
        assert!(exists<PrivacyVault<CoinType>>(vault_addr), error::not_found(E_VAULT_NOT_INITIALIZED));
        let vault = borrow_global_mut<PrivacyVault<CoinType>>(vault_addr);
        let coins_to_deposit = coin::withdraw<CoinType>(sender, amount);
        coin::merge(&mut vault.deposits, coins_to_deposit);
        let commitment = Commitment { point: commitment_point, ciphertext };
        let commitment_index = vault.merkle_tree.next_index;
        table::add(&mut vault.commitments, commitment_index, commitment);
        merkle_insert(&mut vault.merkle_tree, commitment_point);
    }

    public fun get_current_root<CoinType>(): vector<u8> acquires PrivacyVault {
        let vault_addr = @zentai_vault;
        assert!(exists<PrivacyVault<CoinType>>(vault_addr), error::not_found(E_VAULT_NOT_INITIALIZED));
        let vault = borrow_global<PrivacyVault<CoinType>>(vault_addr);
        let tree = &vault.merkle_tree;

        let num_leaves = tree.next_index;
        if (num_leaves == 0) {
            return merkle_get_empty_root();
        };
        let top_level = MERKLE_TREE_DEPTH;
        *vector::borrow(vector::borrow(&tree.levels, top_level), 0)
    }

    public fun is_nullifier_used<CoinType>(nullifier_hash: vector<u8>): bool acquires PrivacyVault {
        let vault_addr = @zentai_vault;
        assert!(exists<PrivacyVault<CoinType>>(vault_addr), error::not_found(E_VAULT_NOT_INITIALIZED));
        let vault = borrow_global<PrivacyVault<CoinType>>(vault_addr);
        table::contains(&vault.nullifiers, nullifier_hash)
    }

    fun internal_hash(left: &vector<u8>, right: &vector<u8>): vector<u8> {
        let combined = vector[];
        vector::append(&mut combined, *left);
        vector::append(&mut combined, *right);
        hash::sha3_256(combined)
    }

    fun get_zero_value(level: u64): vector<u8> {
        let current_hash = hash::sha3_256(b"ZERO");
        let i = 0;
        while (i < level) {
            current_hash = internal_hash(&current_hash, &current_hash);
            i = i + 1;
        };
        current_hash
    }

    fun merkle_get_empty_root(): vector<u8> {
        get_zero_value(MERKLE_TREE_DEPTH)
    }

    fun merkle_insert(tree: &mut MerkleTree, leaf: vector<u8>) {
        let leaf_index = tree.next_index;
        assert!((leaf_index as u128) < (1u128 << (MERKLE_TREE_DEPTH as u8)), error::out_of_range(E_MERKLE_TREE_IS_FULL));

        let current_node = leaf;
        let current_index = leaf_index;
        let level = 0;
        
        while (level < MERKLE_TREE_DEPTH) {
            let level_nodes = vector::borrow_mut(&mut tree.levels, level);
            vector::push_back(level_nodes, current_node);
            
            let sibling_node = if (current_index % 2 == 0) {
                get_zero_value(level)
            } else {
                *vector::borrow(level_nodes, current_index - 1)
            };

            if (current_index % 2 == 0) {
                current_node = internal_hash(&current_node, &sibling_node);
            } else {
                current_node = internal_hash(&sibling_node, &current_node);
            };
            
            current_index = current_index / 2;
            level = level + 1;
        };
        
        let top_level_nodes = vector::borrow_mut(&mut tree.levels, MERKLE_TREE_DEPTH);
        if (vector::length(top_level_nodes) > 0) {
             *vector::borrow_mut(top_level_nodes, 0) = current_node;
        } else {
            vector::push_back(top_level_nodes, current_node);
        };

        tree.next_index = leaf_index + 1;
        table::add(&mut tree.roots, current_node, true);
    }
}