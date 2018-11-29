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

#include "argon2.h"
#include "core.h"
#include "encoding.h"

#define T_COST_DEF 3
#define LOG_M_COST_DEF 12 /* 2^12 = 4 MiB */
#define LANES_DEF 1
#define THREADS_DEF 1
#define OUT_LEN 32
#define SALT_LEN 16
#define ENCODE_LEN 96 /* Does not include SALT LEN */

/* Workaround for https://github.com/technion/ruby-argon2/issues/8. Hopefully temporary */
static int wrap_compare(const uint8_t *b1, const uint8_t *b2, size_t len) {
    size_t i;
    uint8_t d = 0U;

    for (i = 0U; i < len; i++) {
        d |= b1[i] ^ b2[i];
    }
    return (int)((1 & ((d - 1) >> 8)) - 1);
}

int argon2_wrap_version(char *out, const char *pwd, size_t pwd_length,
        uint8_t *salt,  uint32_t saltlen, uint32_t t_cost, uint32_t m_cost, 
        uint32_t lanes, uint8_t *secret, size_t secretlen, uint32_t version)
{
    uint8_t hash[OUT_LEN];
    argon2_context context;

    if (!pwd) {
        return ARGON2_PWD_PTR_MISMATCH;
    }

    if (!salt) {
        return ARGON2_PWD_PTR_MISMATCH;
    }

    context.out = hash;
    context.outlen = OUT_LEN;
    context.pwd = (uint8_t *)pwd;
    context.pwdlen = pwd_length;
    context.salt = salt;
    context.saltlen = saltlen;
    context.secret = secret;
    context.secretlen = secretlen;
    context.ad = NULL;
    context.adlen = 0;
    context.t_cost = t_cost;
    context.m_cost = m_cost;
    context.lanes = lanes;
    context.threads = lanes;
    context.allocate_cbk = NULL;
    context.free_cbk = NULL;
    context.flags = 0;
    context.version = version;

    int result = argon2i_ctx(&context);
    if (result != ARGON2_OK)
        return result;

    encode_string(out, ENCODE_LEN + saltlen, &context, Argon2_i);
    return ARGON2_OK;
}
 
/* Since all new hashes will use latest version, this wraps the 
   * function including the version
   */
int argon2_wrap(char *out, const char *pwd, size_t pwd_length,
        uint8_t *salt,  uint32_t saltlen, uint32_t t_cost, uint32_t m_cost, 
        uint32_t lanes, uint8_t *secret, size_t secretlen)
{
    return argon2_wrap_version(out, pwd, pwd_length, salt, saltlen,
            t_cost, m_cost, lanes, secret, secretlen, ARGON2_VERSION_13);
}

int wrap_argon2_verify(const char *encoded, const char *pwd,
    const size_t pwdlen,
    uint8_t *secret, size_t secretlen)
{
    argon2_context ctx;
    int ret;
    char *out;
    memset(&ctx, 0, sizeof(argon2_context));
    size_t encoded_len;
    
    encoded_len = strlen(encoded);
    /* larger than max possible values */
    ctx.saltlen = encoded_len;
    ctx.outlen = encoded_len;

    ctx.salt = malloc(ctx.saltlen);
    ctx.out = malloc(ctx.outlen);
    if (!ctx.out || !ctx.salt) {
        free(ctx.salt);
        free(ctx.out);
        return ARGON2_MEMORY_ALLOCATION_ERROR;
    }

    if(decode_string(&ctx, encoded, Argon2_i) != ARGON2_OK) {
        free(ctx.salt);
        free(ctx.out);
        return ARGON2_DECODING_FAIL;
    } 

    out = malloc(ENCODE_LEN + ctx.saltlen);
    if(!out) {
        free(ctx.salt);
        free(ctx.out);
        return ARGON2_DECODING_FAIL;
    }

    ret = argon2_wrap_version(out, pwd, pwdlen, ctx.salt, ctx.saltlen,
            ctx.t_cost, ctx.m_cost, ctx.lanes, secret, secretlen,
            ctx.version);

    free(ctx.salt);

    if (ret != ARGON2_OK || wrap_compare((uint8_t*)out, (uint8_t*)encoded, 
                strlen(encoded))) {
        free(ctx.out);
        free(out);
        return ARGON2_DECODING_FAIL;
    }
    free(ctx.out);
    free(out);

    return ARGON2_OK;
}

