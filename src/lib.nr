// Original implementation on circom: https://github.com/iden3/circomlib/blob/master/circuits/mimcsponge.circom
// implements MiMC-2n/n as hash using a sponge construction.

mod constants;
use constants::get_c_partial;

// log_5(21888242871839275222246405745257275088548364400416034343698204186575808495617) ~= 110
// => nRounds should be 220
global nRounds: Field = 220;

pub fn mimc_sponge<N, M>(ins: [Field; N], k: Field) -> [Field; M] {
    let mut S = MiMCFeistel(ins[0], 0, k); // First round with xL = ins[0] and xR = 0

    for i in 1..N {
        S = MiMCFeistel(S.0 + ins[i], S.1, k);
    }

    let mut resultHashes = [S.0; M];
    for i in 1..M {
        S = MiMCFeistel(S.0, S.1, k);
        resultHashes[i] = S.0;
    }

    resultHashes
}

pub fn MiMCFeistel(mut xL: Field, mut xR: Field, k: Field) -> (Field, Field) {
    let c_partial = get_c_partial();

    for i in 0..nRounds - 1 {
        let t = k + xL + c_partial[i];
        let t5 = t.pow_32(5);

        let xR_prev = xR;
        xR = xL;
        xL = xR_prev + t5;
    }

    (xL, xR + (k + xL).pow_32(5))
}

mod tests {
    use crate::{MiMCFeistel, mimc_sponge};

    // Note: "correct" results are generated with MimcSponge from circom js lib.
    #[test]
    fn test_MiMCFeistel_1() {
        let result = MiMCFeistel(1, 2, 3);

        // Corect result
        let xL = 18444058245820418255538785847032978363886102372504864086197416499869253008979;
        let xR = 2646733164649743153031645792459389637917704265581895142760676293265176296759;

        assert_eq(result.0, xL);
        assert_eq(result.1, xR);
    }

    #[test]
    fn test_MiMCFeistel_2() {
        let result = MiMCFeistel(1000, 999, 10);

        // Corect result
        let xL = 10901886313141654114173884984249295553845963921374737450017021218277910142918;
        let xR = 104045006284528846441423960971557892067967863519844490428108835104029303936;

        assert_eq(result.0, xL);
        assert_eq(result.1, xR);
    }

    #[test]
    fn test_mimc_sponge_1_out_0_key() {
        let arr = [1, 2];
        let result: [Field; 1] = mimc_sponge(arr, 0);

        // Corect result
        let correct_hash = 19814528709687996974327303300007262407299502847885145507292406548098437687919;
        assert_eq(result[0], correct_hash);
    }

    #[test]
    fn test_mimc_sponge_1_out_1_key() {
        let arr = [1, 2];
        let result: [Field; 1] = mimc_sponge(arr, 1);

        // Corect result
        let correct_hash = 17236896413376377405058789859087828421021693769244747084144187442081779648555;
        assert_eq(result[0], correct_hash);
    }

    #[test]
    fn test_mimc_sponge_5_out_1_key() {
        let arr = [1, 2];
        let result: [Field; 5] = mimc_sponge(arr, 1);

        let correct_hashes = [
            17236896413376377405058789859087828421021693769244747084144187442081779648555,
            11277431585714687959756913953500718398698117158935573693854558567642894739840,
            6278145577450803074031982731957090202566144856752520017884416575766434946378,
            12651595119786250583026895490442607289535608047821356164143881978050785756833,
            8912100262698853704050637333012330554483566520224383207674594878312248771235
        ];

        for i in 0..5 {
            assert_eq(result[i], correct_hashes[i]);
        }
    }

    #[test]
    fn test_mimc_sponge_10_out_9999_key() {
        let arr = [1, 2];
        let result: [Field; 10] = mimc_sponge(arr, 9999);

        let correct_hashes = [
            19696274780606372486682072577149389639173872833380964314108564693983208134610,
            21463088005942133698539809356934089173745795630507899524560843549522264805240,
            15537194216317608430015583646569854782008147899014268946541376373826671085760,
            419386924697698083051185358686967840390743528981656867994595629489173973763,
            4777955323564825413799836357205702174365239956174483358613227755910155902692,
            16373989717496515907022371949529063756833483303537825972318949877683398699964,
            6078969220664201320295197822088352652167693666657917048113647884224203133639,
            17096329303001707143485439428695259901328442420826506699246308239334809738369,
            16368760450270087766445061161403432453956546182428256263547562186231660824911,
            3913868527477801202550717485487644586105175063459393923848224418988820619575
        ];

        for i in 0..10 {
            assert_eq(result[i], correct_hashes[i]);
        }
    }

    #[test]
    fn test_mimc_sponge_0_out() {
        let arr = [1, 2];
        let result: [Field;0] = mimc_sponge(arr, 0);
        assert_eq(result.len(), 0);
    }
}
