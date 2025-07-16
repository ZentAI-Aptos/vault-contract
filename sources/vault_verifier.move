module zentai_vault::vault_verifier {
    use std::vector;
    use std::option;
    use aptos_std::crypto_algebra::{Element, deserialize, neg, pairing};
    // Uses the BN254 curve, compatible with snarkjs
    use aptos_std::bn254_algebra::{G1, G2, Gt, Fr, FormatG1Uncompr, FormatG2Uncompr, FormatGt, FormatFrLsb};
    use zentai_vault::groth16_verifier;

    const E_VERIFICATION_KEY_NOT_INITIALIZED: u64 = 101;
    const E_DESERIALIZATION_FAILED: u64 = 102;

    /// Struct to store the Verification Key as raw bytes.
    /// These data types have 'store' ability and can be stored.
    struct VerificationKeyStore has key {
        vk_alpha_g1_bytes: vector<u8>,
        vk_beta_g2_bytes: vector<u8>,
        vk_gamma_g2_bytes: vector<u8>,
        vk_delta_g2_bytes: vector<u8>,
        vk_uvw_gamma_g1_bytes: vector<vector<u8>>,
    }

    /// Initializes and stores the Verification Key as bytes.
    public fun initialize(
        account: &signer,
        vk_alpha_g1_bytes: vector<u8>,
        vk_beta_g2_bytes: vector<u8>,
        vk_gamma_g2_bytes: vector<u8>,
        vk_delta_g2_bytes: vector<u8>,
        vk_uvw_gamma_g1_bytes: vector<vector<u8>>,
    ) {
        move_to(account, VerificationKeyStore {
            vk_alpha_g1_bytes,
            vk_beta_g2_bytes,
            vk_gamma_g2_bytes,
            vk_delta_g2_bytes,
            vk_uvw_gamma_g1_bytes,
        });
    }

    /// Main function to verify the withdrawal proof.
    public fun verify_withdraw_proof(
        account: &signer, // A signer is required to enable native crypto functions
        public_inputs_bytes: &vector<vector<u8>>,
        proof_a_bytes: &vector<u8>,
        proof_b_bytes: &vector<u8>,
        proof_c_bytes: &vector<u8>,
    ): bool acquires VerificationKeyStore {
        // Enable native crypto functions for this transaction

        let deployer_addr = @zentai_vault;
        assert!(exists<VerificationKeyStore>(deployer_addr), E_VERIFICATION_KEY_NOT_INITIALIZED);
        let vk_store = borrow_global<VerificationKeyStore>(deployer_addr);

        // --- Deserialize and Prepare VK within the transaction ---
        let vk_alpha_g1 = option::extract(&mut deserialize<G1, FormatG1Uncompr>(&vk_store.vk_alpha_g1_bytes));
        let vk_beta_g2 = option::extract(&mut deserialize<G2, FormatG2Uncompr>(&vk_store.vk_beta_g2_bytes));
        let vk_gamma_g2 = option::extract(&mut deserialize<G2, FormatG2Uncompr>(&vk_store.vk_gamma_g2_bytes));
        let vk_delta_g2 = option::extract(&mut deserialize<G2, FormatG2Uncompr>(&vk_store.vk_delta_g2_bytes));

        let pvk_alpha_g1_beta_g2 = pairing<G1, G2, Gt>(&vk_alpha_g1, &vk_beta_g2);
        let pvk_gamma_g2_neg = neg<G2>(&vk_gamma_g2);
        let pvk_delta_g2_neg = neg<G2>(&vk_delta_g2);

        let pvk_uvw_gamma_g1 = vector[];
        let i = 0;
        while (i < vector::length(&vk_store.vk_uvw_gamma_g1_bytes)) {
            let element_bytes = vector::borrow(&vk_store.vk_uvw_gamma_g1_bytes, i);
            let element = option::extract(&mut deserialize<G1, FormatG1Uncompr>(element_bytes));
            vector::push_back(&mut pvk_uvw_gamma_g1, element);
            i = i + 1;
        };
        // --- End of preparation ---

        // Deserialize proof
        let proof_a = option::extract(&mut deserialize<G1, FormatG1Uncompr>(proof_a_bytes));
        let proof_b = option::extract(&mut deserialize<G2, FormatG2Uncompr>(proof_b_bytes));
        let proof_c = option::extract(&mut deserialize<G1, FormatG1Uncompr>(proof_c_bytes));

        // Deserialize public inputs
        let public_inputs = vector[];
        let i = 0;
        while (i < vector::length(public_inputs_bytes)) {
            let input_bytes = vector::borrow(public_inputs_bytes, i);
            let input_fr = option::extract(&mut deserialize<Fr, FormatFrLsb>(input_bytes));
            vector::push_back(&mut public_inputs, input_fr);
            i = i + 1;
        };
        assert!(vector::length(&public_inputs) > 0, E_DESERIALIZATION_FAILED);

        // Call the optimized verification function from the groth16 module
        groth16_verifier::verify_proof_prepared<G1, G2, Gt, Fr>(
            &pvk_alpha_g1_beta_g2,
            &pvk_gamma_g2_neg,
            &pvk_delta_g2_neg,
            &pvk_uvw_gamma_g1,
            &public_inputs,
            &proof_a,
            &proof_b,
            &proof_c,
        )
    }
}