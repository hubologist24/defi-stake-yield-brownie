// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    address[] public allowedTokens;
    address[] public staker;
    //mapping  token staker amount
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokenState;
    event stakingBalanceEvent(address token, address staker, uint256 amount);
    mapping(address => address) public tokenPriceFeedMapping;
    IERC20 public dappToken;

    event stakingBalanceCalcEvent(uint256 indexed price);

    constructor(address _dappTokenAddress) {
        dappToken = IERC20(_dappTokenAddress);
    }

    function issueToken() public onlyOwner {
        for (
            uint256 stakerIndex = 0;
            stakerIndex < staker.length;
            stakerIndex++
        ) {
            uint256 calcaulatedAmount;
            // kendimce
            // staker_ =staker[stakerIndex] issuedAmount /
            // 1000000 = stakingBalance[_token][staker[stakerIndex]];
            address recipient = staker[stakerIndex];
            calcaulatedAmount = getUserTotalValue(recipient);
            emit stakingBalanceCalcEvent(calcaulatedAmount);
            dappToken.transfer(recipient, calcaulatedAmount);
            //transfer bu contracttan oldugu icin
            //transfer from baska hesapdan
        }
    }

    //kendi denemem
    function getUserTotalValue(address _recipient)
        public
        view
        returns (uint256)
    {
        uint256 totalValue = 0;
        require(uniqueTokenState[_recipient] > 0, "no staked ");
        for (
            uint256 stakerIndex = 0;
            stakerIndex < staker.length;
            stakerIndex++
        ) {
            address selectedStaker = staker[stakerIndex];
            for (
                uint256 allowedIndex = 0;
                allowedIndex < allowedTokens.length;
                allowedIndex++
            ) {
                address selectedAllowedToken = allowedTokens[allowedIndex];
                uint256 selectedTokenBalance = stakingBalance[
                    selectedAllowedToken
                ][selectedStaker];
                (uint256 price, uint256 decimals) = getTokenValue(
                    selectedAllowedToken
                );
                totalValue =
                    totalValue +
                    ((selectedTokenBalance * price) / (10**decimals));
                /*emit stakingBalanceCalcEvent(
                    selectedAllowedToken,
                    price,
                    decimals
                );
                */
            }
        }
        return totalValue;
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        uint256 decimals = priceFeed.decimals();
        //price int
        return (uint256(price), decimals);
    }

    function setPriceFeedAddress(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    //sadece bu contract cagirabiliyor
    //mappingin karsili uint256 gibi düsün başta 0 la başlıyor 1 eklediğimizde
    function updateUniqueStaker(address _sender, address _token) internal {
        if (stakingBalance[_token][_sender] <= 0)
            uniqueTokenState[_sender] = uniqueTokenState[_sender] + 1;
    }

    function unstakeTokenss(address _token) public {
        uint256 tokenBalance = stakingBalance[_token][msg.sender];
        require(tokenBalance > 0, "must be greater 0");
        IERC20(_token).transfer(msg.sender, tokenBalance);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokenState[msg.sender] = uniqueTokenState[msg.sender] - 1;
    }

    function stakeTokens(uint256 _amount, address _token) public {
        require(_amount > 0, "Not enough value");
        require(tokenIsAllowed(_token), "Token not allowed");
        //abiyle importluyu cagirdik gibi bisiler
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        updateUniqueStaker(msg.sender, _token);
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
        //stakingBalance da yok   ve 0 update le bir olmus yeni
        //stakers arraye eklicez
        //flag gibi altı
        if (uniqueTokenState[msg.sender] == 1) {
            staker.push(msg.sender);
        }
        emit stakingBalanceEvent(_token, msg.sender, _amount);
    }

    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function tokenIsAllowed(address _token) public returns (bool) {
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            if (_token == allowedTokens[allowedTokensIndex]) return true;
        }
        return false;
    }
}
