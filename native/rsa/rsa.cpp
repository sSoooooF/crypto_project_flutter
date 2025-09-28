#include <gmpxx.h>
#include <iostream>

int main(int argc, char* argv[]) {
    int bits = argc > 1 ? atoi(argv[1]) : 16384;
    gmp_randclass rr(gmp_randinit_default);
    rr.seed(time(NULL));
    mpz_class p = rr.get_z_bits(bits);
    mpz_nextprime(p.get_mpz_t(), p.get_mpz_t());
    std::cout << p.get_str(10) << std::endl;
    return 0;
}

