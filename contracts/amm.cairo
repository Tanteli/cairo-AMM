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

struct SwapTransaction:
    member account_id : felt
    member token_a_amount : felt
end

struct AmmBatchOutput:
    # balances of AMM before/after applying batch
    member token_a_before : felt
    member token_b_before : felt
    member token_a_after : felt
    member token_b_after : felt
    # account merkle roots
    member account_root_before : felt
    member account_root_after : felt
end

func modify_account{range_check_ptr}(state : AMMState, account_id, diff_a, diff_b) -> (
    state : AMMState, key
):
    alloc_locals

    # define reference to state.account_dict_end so that we have implicit argument to the dict functions
    let account_dict_end = state.account_dict_end

    # retrieve the pointer to current state of the account
    let (local old_account : Account*) = dict_read{dict_ptr=account_dict_end}(key=account_id)

    tempvar new_token_a_balance = (
        old_account.token_a_balance + diff_a)
    tempvar new_token_b_balance = (
        old_account.token_b_balance + diff_b)

    assert_nn_le(new_token_a_balance, MAX_BALANCE)
    assert_nn_le(new_token_b_balance, MAX_BALANCE)

    local new_account : Account
    assert new_account.public_key = old_account.public_key
    assert new_account.token_a_balance = new_token_a_balance
    assert new_account.token_b_balance = new_token_b_balance

    # perform update
    let (__fp__, _) = get_fp_and_pc()
    dict_write{dict_ptr=account_dict_end}(key=account_id, new_value=cast(&new_account, felt))

    # construct, return state
    local new_state : AMMState
    assert new_state.account_dict_start = (state.account_dict_start)
    assert new_state.account_dict_end = account_dict_end
    assert new_state.token_a_balance = state.token_a_balance
    assert new_state.token_b_balance = state.token_b_balance

    return (state=new_state, key=old_account.public_key)
end
