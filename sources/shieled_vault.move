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


    // Error codes for the vault module
    const E_VAULT_ALREADY_INITIALIZED: u64 = 1;
    const E_VAULT_NOT_INITIALIZED: u64 = 2;
    const E_INVALID_AMOUNT: u64 = 3;
    const E_MERKLE_TREE_IS_FULL: u64 = 4;
    const E_NULLIFIER_ALREADY_USED: u64 = 5;
    const E_INVALID_MERKLE_ROOT: u64 = 6;
    const E_INVALID_PROOF: u64 = 7;
    const E_INVALID_RECIPIENT: u64 = 8;
    const E_DESERIALIZATION_FAILED: u64 = 9;

    // The fixed depth of the Merkle tree
    const MERKLE_TREE_DEPTH: u64 = 32;
    /// Domain separation tag for Bulletproofs, inspired by sample code.
    const BULLETPROOF_DST: vector<u8> = b"ZENTAI_SHIELDED_VAULT_V2";


    /// Event emitted when a new deposit is made to the vault.
    #[event]
    struct DepositEvent has drop, store {
        commitment_index: u64,
        commitment_point: vector<u8>,
        timestamp: u64,
    }

    /// Event emitted when a successful withdrawal occurs from the vault.
    #[event]
    struct WithdrawEvent has drop, store {
        recipient: address,
        amount: u64,
        nullifier_hash: vector<u8>,
    }
    
    /// Represents a private commitment in the vault.
    /// `point`: The cryptographic commitment point (e.g., Pedersen commitment).
    /// `ciphertext`: Encrypted data associated with the commitment.
    struct Commitment has store {
        point: vector<u8>,
        ciphertext: vector<u8>,
    }

    /// Represents the Merkle tree structure used to track commitments.
    /// `levels`: A vector of vectors, where each inner vector holds the hashes at a specific level of the tree.
    /// `next_index`: The index for the next available leaf in the tree.
    /// `roots`: A table storing all historical Merkle roots to allow for proof verification against past states.
    struct MerkleTree has store {
        levels: vector<vector<vector<u8>>>,
        next_index: u64,
        roots: Table<vector<u8>, bool>,
    }

    /// The main resource representing the privacy vault for a specific CoinType.
    /// `deposits`: A Coin store holding the total deposited funds of this CoinType.
    /// `commitments`: A table mapping commitment indices to their `Commitment` data.
    /// `nullifiers`: A table tracking used nullifier hashes to prevent double-spending.
    /// `merkle_tree`: The Merkle tree instance for the vault.
    struct PrivacyVault<phantom CoinType> has key {
        deposits: Coin<CoinType>,
        commitments: Table<u64, Commitment>,
        nullifiers: Table<vector<u8>, bool>,
        merkle_tree: MerkleTree,
    }


    /// Withdraws funds from the vault by spending an old commitment and creating a change commitment.
    /// This function requires a ZK-Groth16 proof to validate the transaction privately.
    public entry fun withdraw<CoinType>(
        account: &signer, // Signer is required to enable native crypto functions for this transaction.
        // Public inputs for the ZK circuit. These must match the circuit's expected public inputs.
        amount: u64,
        recipient: address,
        merkle_root: vector<u8>,
        nullifier_hash: vector<u8>,
        change_commitment_bytes: vector<u8>,
        // Auxiliary data associated with the withdrawal.
        change_ciphertext_bytes: vector<u8>,
        // ZK-Groth16 proof components as byte vectors.
        proof_a_bytes: vector<u8>,
        proof_b_bytes: vector<u8>,
        proof_c_bytes: vector<u8>,
    ): bool acquires PrivacyVault {
        // Ensure the withdrawal amount is positive.
        assert!(amount > 0, error::invalid_argument(E_INVALID_AMOUNT));
        let vault_addr = @zentai_vault;
        // Ensure the vault resource exists at the expected address.
        assert!(exists<PrivacyVault<CoinType>>(vault_addr), error::not_found(E_VAULT_NOT_INITIALIZED));
        let vault = borrow_global_mut<PrivacyVault<CoinType>>(vault_addr);

        // 1. Validate Merkle Root and Nullifier (core business logic for privacy).
        // Check if the provided Merkle root is a known historical root of the tree.
        assert!(table::contains(&vault.merkle_tree.roots, merkle_root), error::invalid_argument(E_INVALID_MERKLE_ROOT));
        // Check if the nullifier hash has already been used to prevent double-spending.
        assert!(!table::contains(&vault.nullifiers, nullifier_hash), error::invalid_argument(E_NULLIFIER_ALREADY_USED));

        // 2. Prepare public inputs for the ZK verifier.
        // The order of these inputs must EXACTLY match the order defined in the Circom circuit.
        let public_inputs_bytes = vector[
            bcs::to_bytes(&merkle_root),
            bcs::to_bytes(&nullifier_hash),
            bcs::to_bytes(&recipient),
            bcs::to_bytes(&amount),
            bcs::to_bytes(&change_commitment_bytes)
        ];

        // 3. CALL THE ZK-SNARK VERIFICATION FUNCTION.
        // The entire complexity of ZK-SNARK verification is encapsulated in a single, efficient call!
        let is_proof_valid = vault_verifier::verify_withdraw_proof(
            account, // Pass signer to enable native crypto operations within the verifier.
            &public_inputs_bytes,
            &proof_a_bytes,
            &proof_b_bytes,
            &proof_c_bytes,
        );
        // Assert that the ZK proof is valid. If not, the transaction will revert.
        assert!(is_proof_valid, error::permission_denied(E_INVALID_PROOF));

        // 4. Update vault state if the ZK proof is valid.
        // Create a new commitment for the change amount (if any).
        let new_commitment = Commitment {
            point: change_commitment_bytes,
            ciphertext: change_ciphertext_bytes,
        };
        // Add the new commitment to the vault's commitments table.
        let new_commitment_index = vault.merkle_tree.next_index;
        table::add(&mut vault.commitments, new_commitment_index, new_commitment);
        // Insert the new commitment into the on-chain Merkle tree.
        merkle_insert(&mut vault.merkle_tree, change_commitment_bytes);
        
        // Mark the nullifier hash as used to prevent future double-spending.
        table::add(&mut vault.nullifiers, nullifier_hash, true);
        // Extract the specified amount of coins from the vault's deposits.
        let withdrawn_coins = coin::extract(&mut vault.deposits, amount);
        // Deposit the withdrawn coins to the recipient's address.
        coin::deposit(recipient, withdrawn_coins);
    }
    
    /// Initializes the PrivacyVault resource and deploys the ZK-Groth16 Verification Key.
    /// This function needs to be called once by the deployer account.
    public entry fun initialize_vault<CoinType>(
        deployer: &signer,
        // Verification Key parameters required to initialize the `vault_verifier` module.
        vk_alpha_g1_bytes: vector<u8>,
        vk_beta_g2_bytes: vector<u8>,
        vk_gamma_g2_bytes: vector<u8>,
        vk_delta_g2_bytes: vector<u8>,
        vk_uvw_gamma_g1_bytes: vector<vector<u8>>,
    ) {
        let deployer_addr = signer::address_of(deployer);
        // Ensure the vault has not been initialized already for this CoinType.
        assert!(!exists<PrivacyVault<CoinType>>(deployer_addr), error::already_exists(E_VAULT_ALREADY_INITIALIZED));
        
        // Initialize the `vault_verifier` module with the provided Verification Key.
        vault_verifier::initialize(
            deployer,
            vk_alpha_g1_bytes,
            vk_beta_g2_bytes,
            vk_gamma_g2_bytes,
            vk_delta_g2_bytes,
            vk_uvw_gamma_g1_bytes,
        );

        // Initialize the vault's Merkle tree structure.
        let levels = vector[];
        let i = 0;
        while (i <= MERKLE_TREE_DEPTH) {
            vector::push_back(&mut levels, vector[]);
            i = i + 1;
        };
        // Create a new MerkleTree instance with empty levels and a new roots table.
        let tree = MerkleTree { levels, next_index: 0, roots: table::new() };
        // Create the PrivacyVault resource.
        let vault = PrivacyVault<CoinType> {
            deposits: coin::zero<CoinType>(), // Initialize with zero coins.
            commitments: table::new(),        // Initialize an empty commitments table.
            nullifiers: table::new(),         // Initialize an empty nullifiers table.
            merkle_tree: tree,                // Assign the newly created Merkle tree.
        };
        // Move the PrivacyVault resource under the deployer's account.
        move_to(deployer, vault);
    }

    /// Deposits funds into the privacy vault.
    /// The `commitment_point` and `ciphertext` are generated off-chain using private data.
    public entry fun deposit<CoinType>(
        sender: &signer,
        amount: u64,
        commitment_point: vector<u8>,
        ciphertext: vector<u8>,
    ) acquires PrivacyVault {
        // Ensure the deposit amount is positive.
        assert!(amount > 0, error::invalid_argument(E_INVALID_AMOUNT));
        let vault_addr = @zentai_vault;
        // Ensure the vault resource exists.
        assert!(exists<PrivacyVault<CoinType>>(vault_addr), error::not_found(E_VAULT_NOT_INITIALIZED));
        let vault = borrow_global_mut<PrivacyVault<CoinType>>(vault_addr);
        
        // Withdraw coins from the sender's account.
        let coins_to_deposit = coin::withdraw<CoinType>(sender, amount);
        // Merge the withdrawn coins into the vault's deposit balance.
        coin::merge(&mut vault.deposits, coins_to_deposit);
        
        // Create a new Commitment struct.
        let commitment = Commitment { point: commitment_point, ciphertext };
        // Get the next available index for the new commitment.
        let commitment_index = vault.merkle_tree.next_index;
        // Add the commitment to the vault's commitments table.
        table::add(&mut vault.commitments, commitment_index, commitment);
        // Insert the commitment point as a leaf into the Merkle tree.
        merkle_insert(&mut vault.merkle_tree, commitment_point);
    }

    /// Returns the current Merkle root of the vault's Merkle tree.
    public fun get_current_root<CoinType>(): vector<u8> acquires PrivacyVault {
        let vault_addr = @zentai_vault;
        // Ensure the vault resource exists.
        assert!(exists<PrivacyVault<CoinType>>(vault_addr), error::not_found(E_VAULT_NOT_INITIALIZED));
        let vault = borrow_global<PrivacyVault<CoinType>>(vault_addr);
        let tree = &vault.merkle_tree;

        let num_leaves = tree.next_index;
        // If no leaves have been inserted, return the empty root value.
        if (num_leaves == 0) {
            return merkle_get_empty_root();
        };
        // Otherwise, return the hash at the top level (root) of the Merkle tree.
        let top_level = MERKLE_TREE_DEPTH;
        *vector::borrow(vector::borrow(&tree.levels, top_level), 0)
    }

    /// Checks if a given nullifier hash has already been used.
    public fun is_nullifier_used<CoinType>(nullifier_hash: vector<u8>): bool acquires PrivacyVault {
        let vault_addr = @zentai_vault;
        // Ensure the vault resource exists.
        assert!(exists<PrivacyVault<CoinType>>(vault_addr), error::not_found(E_VAULT_NOT_INITIALIZED));
        let vault = borrow_global<PrivacyVault<CoinType>>(vault_addr);
        // Check if the nullifier hash exists in the used nullifiers table.
        table::contains(&vault.nullifiers, nullifier_hash)
    }

    /// Internal helper function to compute the SHA3-256 hash of two concatenated byte vectors.
    /// Used for Merkle tree node hashing.
    fun internal_hash(left: &vector<u8>, right: &vector<u8>): vector<u8> {
        let combined = vector[];
        vector::append(&mut combined, *left);
        vector::append(&mut combined, *right);
        hash::sha3_256(combined)
    }

    /// Computes the zero value (placeholder hash) for a given Merkle tree level.
    /// These are used for empty branches in the Merkle tree.
    fun get_zero_value(level: u64): vector<u8> {
        // Base hash for level 0.
        let current_hash = hash::sha3_256(b"ZERO");
        let i = 0;
        // Hash the zero value with itself for each subsequent level.
        while (i < level) {
            current_hash = internal_hash(&current_hash, &current_hash);
            i = i + 1;
        };
        current_hash
    }

    /// Returns the Merkle root for an empty tree of the defined depth.
    fun merkle_get_empty_root(): vector<u8> {
        get_zero_value(MERKLE_TREE_DEPTH)
    }

    /// Inserts a new leaf (commitment point) into the Merkle tree.
    /// This function updates the tree's levels and stores the new root.
    fun merkle_insert(tree: &mut MerkleTree, leaf: vector<u8>) {
        let leaf_index = tree.next_index;
        // Assert that the tree is not full.
        assert!((leaf_index as u128) < (1u128 << (MERKLE_TREE_DEPTH as u8)), error::out_of_range(E_MERKLE_TREE_IS_FULL));

        let current_node = leaf;
        let current_index = leaf_index;
        let level = 0;
        
        // Iterate through each level of the Merkle tree from bottom to top.
        while (level < MERKLE_TREE_DEPTH) {
            let level_nodes = vector::borrow_mut(&mut tree.levels, level);
            // Add the current_node to the current level's nodes.
            vector::push_back(level_nodes, current_node);
            
            // Determine the sibling node for the current_node.
            let sibling_node = if (current_index % 2 == 0) {
                // If current_node is a left child, its sibling is a zero value if it's the first node at this level,
                // or the previous node if it's not. (Correction: this logic implies a sparse tree or specific padding)
                // For a dense tree, it would be the next node at the same level if it exists, or a zero value.
                // The current implementation seems to assume a specific tree construction where the sibling is either
                // a zero value (if current_node is left child) or the previous node (if current_node is right child).
                get_zero_value(level) // This implies padding with zero values for incomplete levels.
            } else {
                *vector::borrow(level_nodes, current_index - 1) // Sibling is the previous node at this level.
            };

            // Hash the current_node with its sibling to get the parent node.
            // Order matters for hashing: left_child || right_child.
            if (current_index % 2 == 0) {
                current_node = internal_hash(&current_node, &sibling_node);
            } else {
                current_node = internal_hash(&sibling_node, &current_node);
            };
            
            // Move up to the parent's level.
            current_index = current_index / 2;
            level = level + 1;
        };
        
        // After iterating through all levels, current_node is the new root.
        let top_level_nodes = vector::borrow_mut(&mut tree.levels, MERKLE_TREE_DEPTH);
        // Update or push the new root to the top level.
        if (vector::length(top_level_nodes) > 0) {
            *vector::borrow_mut(top_level_nodes, 0) = current_node;
        } else {
            vector::push_back(top_level_nodes, current_node);
        };

        // Increment the index for the next leaf.
        tree.next_index = leaf_index + 1;
        // Add the new root to the table of historical roots.
        table::add(&mut tree.roots, current_node, true);
    }
}