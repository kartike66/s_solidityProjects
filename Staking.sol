//  Stake: Lock tokens into our smart contract
// withdraw: unlock tokens and pull out of the contract
// claimReward: user get their reward tokens
// What's some good reward math

// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
error Staking__TransferFailed();
error Staking__NeedsMoreThanZero();
contract Staking {

    IERC20 public s_stakingToken;
    IERC20 public s_rewardToken;
    uint256 public s_totalSupply;
    uint256 public s_rewardPerTokenStored;

    mapping(address => uint256) public s_balances;
    mapping(address => uint256) public s_userRewardPerTokenPaid;
    mapping(address => uint256) public s_rewards;
    uint256 public constant REWARD_RATE = 100;
    
    uint256 public s_lastUpdateTime;

    modifier updateReward(address account) {
        // how much reward per token?
        // last timestamp
        s_rewardPerTokenStored = rewardPerToken();
        s_lastUpdateTime = block.timestamp;
        s_rewards[account] = earned(account);
        s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;
        _;

    }

    modifier moreThanZero(uint256 amount){
        if(amount == 0){
            revert Staking__NeedsMoreThanZero();
        }
        _;
    }

    constructor(address stakingToken, address rewardToken) {   // There is only token that we will allow to stake and we'll input that 
        s_stakingToken = IERC20(stakingToken); // token in the constructor
        // contructor is a function which is used to deploy state variables
        s_rewardToken = IERC20(rewardToken);
    }

    function earned(address account) public view returns(uint256){
        uint256 currentBalance = s_balances[account];

        uint256 amountPaid = s_userRewardPerTokenPaid[account];
        uint256 currentRewardPerToken = rewardPerToken(); 
        uint256 pastRewards = s_rewards[account];

        uint256 _earned = ((currentBalance * (currentRewardPerToken - amountPaid)) / 1e18) + pastRewards;
        return _earned;


         
    }

    // Based on how long it's been during this most recent snapshot 

    function rewardPerToken() public view returns(uint256){
        if (s_totalSupply == 0){
            return s_rewardPerTokenStored;
        }
        return s_rewardPerTokenStored + (((block.timestamp - s_lastUpdateTime) * REWARD_RATE * 1e18)/s_totalSupply);     
    }

    function stake(uint256 amount) external updateReward(msg.sender) moreThanZero(amount) {
        // keep track of how much this user has staked
        // keep track of  how much tokens we have in total
        // transfer the tokens to this contracts
        s_balances[msg.sender] = s_balances[msg.sender] + amount;
        s_totalSupply = s_totalSupply + amount;
        bool success = s_stakingToken.transferFrom(msg.sender, address(this), amount);
        //require(success, "Failed");
        if(!success) {
            revert Staking__TransferFailed();
        }

    }

    function withdraw(uint256 amount) external updateReward(msg.sender) moreThanZero(amount) {
        s_balances[msg.sender] = s_balances[msg.sender] - amount;
        s_totalSupply = s_totalSupply - amount;
        bool success = s_stakingToken.transfer(msg.sender, amount);
        if (!success) {
            revert Staking__TransferFailed();
        }
    }

    function claimReward() external updateReward(msg.sender){
        // How much reward do they get?
        uint256 reward = s_rewards[msg.sender];
        bool success = s_rewardToken.transfer(msg.sender, reward);
        if(!success) {
            revert Staking__TransferFailed();
        }   
          
    }  

     
}