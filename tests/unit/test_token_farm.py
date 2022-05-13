import pytest


from brownie import network, exceptions
from scripts.helpful_scripts import (
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
    get_account,
    get_contract,
)
import pytest
from scripts.deploy import deploy_dapp_token_and_farm


def test_set_price_feed_contract():
    # arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for testnet")
    account = get_account()
    non_owner_account = get_account(index=1)
    token_farm, dapp_token = deploy_dapp_token_and_farm()
    # act
    usd_price_feed = get_contract("eth_usd_price_feed")
    token_farm.setPriceFeedAddress(
        dapp_token.address, usd_price_feed, {"from": account}
    )
    # assert
    assert token_farm.tokenPriceFeedMapping(dapp_token.address) == usd_price_feed
    with pytest.raises(exceptions.VirtualMachineError):
        token_farm.setPriceFeedAddress(
            dapp_token.address, usd_price_feed, {"from": non_owner_account}
        )


def test_stake_tokens(amount_staked):
    # arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for testnet")
    account = get_account()
    token_farm, dapp_token = deploy_dapp_token_and_farm()
    dapp_token.approve(token_farm.address, amount_staked, {"from": account})
    token_farm.stakeTokens(amount_staked, dapp_token.address, {"from": account})
    assert (
        token_farm.stakingBalance(dapp_token.address, account.address) == amount_staked
    )
    assert token_farm.uniqueTokenState(account.address) == 1
    assert token_farm.staker(0) == account.address
    return dapp_token, token_farm, account


def test_issue_tokens(amount_staked):
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for testnet")
    dapp_token, token_farm, account = test_stake_tokens(amount_staked)
    starting_balance = dapp_token.balanceOf(account.address)
    token_farm.issueToken({"from": account})
    assert dapp_token.balanceOf(account.address) == starting_balance + 2000 * 10**18
    # at2000 $ 10**18
    # 1 eth 2000 $
    # we give 2000 dapp for 1 eth
    # DECIMALS = 18
    # amount staked 1 eth
    # 2000 dapp verdik bunun icin adama
    # INITIAL_VALUE = web3.toWei(2000, "ether")
    # mock_price_feed = MockV3Aggregator.deploy(
    #    decimals, initial_value, {"from": account})
    # tx = token_farm.issueToken({"from": account})
    # tx.wait(1)
    # print(tx.events[0]["price"])
    # assert amount_staked + 1 == tx.events[0]["price"]
