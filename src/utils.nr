use dep::curves::ecdsa_secp256k1::fp::PrimeField as Fp;

global MAX_SECP256K1_ELEMENT_BITS: u16 = 256;

unconstrained pub(crate) fn to_bits(fp: Fp) -> [u1; MAX_SECP256K1_ELEMENT_BITS] {
    let bits = fp.to_bits();

    let mut reduced_bits = [0; MAX_SECP256K1_ELEMENT_BITS];

    for i in 0..256 {
        reduced_bits[i] = bits[i];
    }

    reduced_bits
}