use dep::biguint::BigUint56 as BigUint;
use dep::curves::ecdsa_secp256k1::fp::PrimeField as Fp;
use dep::std::option::Option;
use crate::utils::to_bits;
// Affine Secp256k1 point
struct Point {
    x: Fp,
    y: Fp
}

impl Point {
    // creates point without membership check
    pub fn from_raw_unchecked(x: Fp, y: Fp) -> Self {
        Self {
            x, y
        }
    }

    // creates point with membership check.
    // Outputs None if the given coordinates is not on the curve
    pub fn from_raw_checked(x: Fp, y: Fp) -> Option<Self> {
        let curve = secp256k1();

        let point = Point { x, y };

        let mut result: Option<Self> = Option::none();
        if curve.contains(point) {
            result = Option::some(point);
        }

        result
    }
    
    // checks if both points are equal
    pub fn eq(self, other: Self) -> bool {
        self.x.eq(other.x) & self.y.eq(other.y) 
    }

    pub fn identity() -> Self {
        Self { x: Fp::zero(), y: Fp::zero() }
    }

    pub fn is_identity(self) -> bool {
        self.y.eq(Fp::zero())
    }

    pub fn negate(self) -> Self {
        Self {
            x: self.x,
            y: self.y.neg()
        }
    }
}

pub fn secp256k1() -> Secp256k1Curve {
    let a = Fp::zero();
    let b = Fp::from_u56(7 as u56);
    let gen_x = Fp::from_bytes(
        [
        0x98, 0x17, 0xf8, 0x16, 0x5b, 0x81, 0xf2, 0x59,
        0xd9, 0x28, 0xce, 0x2d, 0xdb, 0xfc, 0x9b, 0x02,
        0x07, 0x0b, 0x87, 0xce, 0x95, 0x62, 0xa0, 0x55,
        0xac, 0xbb, 0xdc, 0xf9, 0x7e, 0x66, 0xbe, 0x79
    ]
    );

    let gen_y = Fp::from_bytes(
        [
        0xb8, 0xd4, 0x10, 0xfb, 0x8f, 0xd0, 0x47, 0x9c,
        0x19, 0x54, 0x85, 0xa6, 0x48, 0xb4, 0x17, 0xfd,
        0xa8, 0x08, 0x11, 0x0e, 0xfc, 0xfb, 0xa4, 0x5d,
        0x65, 0xc4, 0xa3, 0x26, 0x77, 0xda, 0x3a, 0x48
    ]
    );

    let gen = Point::from_raw_unchecked(gen_x, gen_y);

    Secp256k1Curve { a, b, gen }
}

struct Secp256k1Curve {
    a: Fp,
    b: Fp,
    gen: Point
}

impl Secp256k1Curve {
    // checks whether the point is on the curve (membership check)
    pub fn contains(self: Self, point: Point) -> bool {
        let y2 = point.y.square();

        let x3 = point.x.square().mul(point.x);

        y2.eq(x3.add(self.b))
    }

    pub fn add(self, p: Point, q: Point) -> Point {
        let mut result = Point::identity();

        // if P is inf, Q or if Q is inf, P
        if p.is_identity() {
            result = q;
        } else if q.is_identity() {
            result = p;
        }

        if !(p.x.eq(q.y) & p.y.eq(q.y.neg())) {
            let mut slope = Fp::zero();

            // P == Q
            if p.eq(q) {
                // slope = 3x^2 + a / 2y
                slope = Fp::from_u56(3).mul(p.x.square()).add(self.a).mul((Fp::from_u56(2).mul(p.y)).invert());
            } 
            // P != Q
            else {
                let den = q.x.sub(p.x);
                let num = q.y.sub(p.y);
                // slope = y2 - y1 / x2 - x1
                slope = num.mul(den.invert());
            }
            // x3 = slope^2 - x1 - x2
            result.x = slope.square().sub(p.x.sub(q.x));
            // y3 = slope(x1 - x3) - y1
            result.y = slope.mul(p.x.sub(result.x)).sub(p.y);
        }

        result
    }

    pub fn fixed_base(self, scalar: Fp) -> Point {
        let mut result = Point::identity();
        let mut base = self.gen;

        let scalar_bits = to_bits(scalar);

        for i in 0..256 {
            if scalar_bits[i] == 1 as u1 {
                result = self.add(result, base);
            }

            base = self.add(base, base);
        }
        result
    }

    pub fn var_base(self, base: Point, scalar: Fp) -> Point {
        let mut result = Point::identity();
        let mut base = base;
        let scalar_bits = to_bits(scalar);

        for i in 0..256 {
            if scalar_bits[i] == 1 as u1 {
                result = self.add(result, base);
            }

            base = self.add(base, base);
        }
        
        result
    }
}

#[test]
fn test_point_1() {
    let x = Fp::zero();
    let y = Fp::from_u56(7);

    let should_be_none = Point::from_raw_checked(x, y);

    assert(should_be_none.is_none());
}

#[test]
fn test_point_2() {
    let Secp256k1Curve { a: _a, b: _b, gen } = secp256k1();

    let should_be_some = Point::from_raw_checked(gen.x, gen.y);

    assert(should_be_some.is_some());
}

#[test]
fn test_eq() {
    let Secp256k1Curve { a: _a, b: _b, gen } = secp256k1();
    let point1 = Point::from_raw_unchecked(gen.x, gen.y);
    let point2 = Point::from_raw_unchecked(gen.x, gen.y);

    assert(point1.eq(point2));
}
