%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.dict import dict_read, dict_write, dict_new, dict_squash, dict_update
from starkware.cairo.common.math import assert_nn_le
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.math import unsigned_div_rem
# from starkware.cairo.common.small_merkle_tree import small_merkle_tree
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (
    call_contract,
    get_contract_address,
    get_caller_address,
    CallContractResponse,
)

# maximum amount of each token that belongs to the AMM
const MAX_BALANCE = 2 ** 64 - 1
const LOG_N_ACCOUNTS = 10

struct Account:
    member public_key : felt
    member token_a_balance : felt
    member token_b_balance : felt
end

struct AMMState:
    # A dictionary that tracks the accounts' state
    member account_dict_start : DictAccess*
    member account_dict_end : DictAccess*
    # The amount of tokens currently in the AMM
    # Must be in the range [0, MAX_BALANCE]
    member token_a_balance : felt
    member token_b_balance : felt
end
