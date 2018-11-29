/* Wrapper for argon Ruby bindings
 * lolware.net
 * Much of this code is based on run.c from the reference implementation
 */
#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <assert.h>

#include "argon2.h"

#define OUT_LEN 32
#define SALT_LEN 16

/**
 * Hashes a password with Argon2i, producing a raw hash
 * @param t_cost Number of iterations
 * @param m_cost Sets memory usage to 2^m_cost kibibytes
 * @param parallelism Number of threads and compute lanes
 * @param pwd Pointer to password
 * @param pwdlen Password size in bytes
 * @param salt Pointer to salt
 * @param saltlen Salt size in bytes
 * @param hash Buffer where to write the raw hash
 * @param hashlen Desired length of the hash in bytes
 * @pre   Different parallelism levels will give different results
 * @pre   Returns ARGON2_OK if successful

int argon2i_hash_raw(const uint32_t t_cost, const uint32_t m_cost,
                     const uint32_t parallelism, const void *pwd,
                     const size_t pwdlen, const void *salt,
                     const size_t saltlen, void *hash, const size_t hashlen);

*/

unsigned int argon2_wrap(char *out, const char *pwd, size_t pwd_length,
    uint8_t *salt, uint32_t saltlen, uint32_t t_cost, uint32_t m_cost, 
    uint32_t lanes, uint8_t *secret, size_t secretlen);

int wrap_argon2_verify(const char *encoded, const char *pwd,
    const size_t pwdlen,
    uint8_t *secret, size_t secretlen);

 
int main()
{
    unsigned char out[OUT_LEN];
    unsigned char hex_out[OUT_LEN*2 + 4]; /* Allow space for NULL byute */
    char out2[300];
    char *pwd = NULL;
    uint8_t salt[SALT_LEN];
    int i, ret;

    memset(salt, 0x00, SALT_LEN); /* pad with null bytes */
    memcpy(salt, "somesalt", 8);


#define RAWTEST(T, M, P, PWD, REF) \
    pwd = strdup(PWD); \
    assert(pwd); \
    ret = argon2i_hash_raw(T, 1<<M, P, pwd, strlen(pwd), salt, SALT_LEN, out, OUT_LEN); \
    assert(ret == ARGON2_OK); \
    for(i=0; i<OUT_LEN; ++i ) \
        sprintf((char*)(hex_out + i*2), "%02x", out[i] ); \
    assert(memcmp(hex_out, REF, OUT_LEN*2) == 0); \
    free(pwd); \
    printf( "Ref test: %s: PASS\n", REF);

    RAWTEST(2, 16, 1, "password", "1c7eeef9e0e969b3024722fc864a1ca9f6ca20da73f9bf3f1731881beae2039e");
    RAWTEST(2, 18, 1, "password", "5c6dfd2712110cf88f1426059b01d87f8210d5368da0e7ee68586e9d4af4954b");
    RAWTEST(2, 8, 1, "password", "dfebf9d4eadd6859f4cc6a9bb20043fd9da7e1e36bdacdbb05ca569f463269f8");
    RAWTEST(1, 16, 1, "password", "fabd1ddbd86a101d326ac2abe79660202b10192925d2fd2483085df94df0c91a");
    RAWTEST(4, 16, 1, "password", "b3b4cb3d6e2c1cb1e7bffdb966ab3ceafae701d6b7789c3f1e6c6b22d82d99d5");
    RAWTEST(2, 16, 1, "differentpassword", "b2db9d7c0d1288951aec4b6e1cd3835ea29a7da2ac13e6f48554a26b127146f9");
    memcpy(salt, "diffsalt", 8);
    RAWTEST(2, 16, 1, "password", "bb6686865f2c1093f70f543c9535f807d5b42d5dc6d71f14a4a7a291913e05e0");


#define WRAP_TEST(T, M, PWD, REF) \
    pwd = strdup(PWD); \
    argon2_wrap(out2, pwd, strlen(PWD), salt, sizeof(salt),T, 1<<M, 1, NULL, 0); \
    free(pwd); \
    assert(memcmp(out2, REF, strlen(REF)) == 0); \
    printf( "Ref test: %s: PASS\n", REF);

    memcpy(salt, "somesalt", 8);
    WRAP_TEST(2, 16, "password", 
            "$argon2i$v=19$m=65536,t=2,p=1$c29tZXNhbHQAAAAAAAAAAA$HH7u+eDpabMCRyL8hkocqfbKINpz+b8/FzGIG+riA54");

    WRAP_TEST(2, 8, "password", 
            "$argon2i$v=19$m=256,t=2,p=1$c29tZXNhbHQAAAAAAAAAAA$3+v51OrdaFn0zGqbsgBD/Z2n4eNr2s27BcpWn0Yyafg");

    WRAP_TEST(2, 16, "differentpassword", 
            "$argon2i$v=19$m=65536,t=2,p=1$c29tZXNhbHQAAAAAAAAAAA$studfA0SiJUa7EtuHNODXqKafaKsE+b0hVSiaxJxRvk");

    ret = wrap_argon2_verify("$argon2i$v=19$m=256,t=2,p=1$c29tZXNhbHQAAAAAAAAAAA$3+v51OrdaFn0zGqbsgBD/Z2n4eNr2s27BcpWn0Yyafg", "password",
            strlen("password"), NULL, 0);
    assert(ret == ARGON2_OK);
    printf("Verify OK test: PASS\n");

    ret = wrap_argon2_verify("$argon2i$v=19$m=65536,t=2,p=1$c29tZXNhbHQAAAAAAAAAAA$iUr0/y4tJvPOFfd6fhwl20W04gQ56ZYXcroZnK3bAB4", "notpassword",
            strlen("notpassword"), NULL, 0);
    assert(ret == ARGON2_DECODING_FAIL);
    printf("Verify FAIL test: PASS\n");
    return 0;


}

