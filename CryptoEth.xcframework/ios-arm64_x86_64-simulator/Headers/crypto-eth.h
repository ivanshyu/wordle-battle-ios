#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

typedef enum ErrorCode {
  Success = 0,
  InvalidInput = 1,
  InnerErr = 2,
} ErrorCode;

typedef struct EthInfo {
  char *address;
  char *private_key;
  char *mnemonic;
} EthInfo;

typedef struct ResultWrapper_EthInfo {
  enum ErrorCode code;
  struct EthInfo value;
  char *err_msg;
} ResultWrapper_EthInfo;

typedef struct BytesWrapper {
  char *bytes;
} BytesWrapper;

typedef struct ResultWrapper_BytesWrapper {
  enum ErrorCode code;
  struct BytesWrapper value;
  char *err_msg;
} ResultWrapper_BytesWrapper;

typedef struct Tx {
  char *to;
  char *from;
  char *data;
  uint64_t nonce;
  uint64_t value;
  uint64_t chain_id;
} Tx;

void enable_trace_log(void);

struct ResultWrapper_EthInfo generate_eth_private_key(char *raw_pwd);

struct ResultWrapper_BytesWrapper create_tx(struct Tx info, char *rpc, char *base58_sk);
