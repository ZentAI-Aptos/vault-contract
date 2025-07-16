module zentai_vault::vault_verifier {
    use std::vector;
    use std::option;
    use aptos_std::crypto_algebra::{Element, deserialize, neg, pairing};
    // Sử dụng đường cong BN254, tương thích với snarkjs
    use aptos_std::bn254_algebra::{G1, G2, Gt, Fr, FormatG1Uncompr, FormatG2Uncompr, FormatGt, FormatFrLsb};
    use zentai_vault::groth16_verifier;

    const E_VERIFICATION_KEY_NOT_INITIALIZED: u64 = 101;
    const E_DESERIALIZATION_FAILED: u64 = 102;

    /// Struct để lưu trữ Khóa Xác Minh dưới dạng byte thô.
    /// Các kiểu dữ liệu này có ability 'store' và có thể được lưu trữ.
    struct VerificationKeyStore has key {
        vk_alpha_g1_bytes: vector<u8>,
        vk_beta_g2_bytes: vector<u8>,
        vk_gamma_g2_bytes: vector<u8>,
        vk_delta_g2_bytes: vector<u8>,
        vk_uvw_gamma_g1_bytes: vector<vector<u8>>,
    }

    /// Khởi tạo và lưu trữ Khóa Xác Minh dưới dạng byte.
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

    /// Hàm chính để xác minh bằng chứng rút tiền.
    public fun verify_withdraw_proof(
        account: &signer, // Cần signer để bật các hàm native crypto
        public_inputs_bytes: &vector<vector<u8>>,
        proof_a_bytes: &vector<u8>,
        proof_b_bytes: &vector<u8>,
        proof_c_bytes: &vector<u8>,
    ): bool acquires VerificationKeyStore {
        // Bật các hàm native crypto cho transaction này

        let deployer_addr = @zentai_vault;
        assert!(exists<VerificationKeyStore>(deployer_addr), E_VERIFICATION_KEY_NOT_INITIALIZED);
        let vk_store = borrow_global<VerificationKeyStore>(deployer_addr);

        // --- Deserialize và Chuẩn bị VK ngay trong giao dịch ---
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
        // --- Kết thúc việc chuẩn bị ---

        // Deserialize bằng chứng
        let proof_a = option::extract(&mut deserialize<G1, FormatG1Uncompr>(proof_a_bytes));
        let proof_b = option::extract(&mut deserialize<G2, FormatG2Uncompr>(proof_b_bytes));
        let proof_c = option::extract(&mut deserialize<G1, FormatG1Uncompr>(proof_c_bytes));

        // Deserialize các đầu vào công khai
        let public_inputs = vector[];
        let i = 0;
        while (i < vector::length(public_inputs_bytes)) {
            let input_bytes = vector::borrow(public_inputs_bytes, i);
            let input_fr = option::extract(&mut deserialize<Fr, FormatFrLsb>(input_bytes));
            vector::push_back(&mut public_inputs, input_fr);
            i = i + 1;
        };
        assert!(vector::length(&public_inputs) > 0, E_DESERIALIZATION_FAILED);

        // Gọi hàm xác minh đã được tối ưu hóa từ module groth16
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