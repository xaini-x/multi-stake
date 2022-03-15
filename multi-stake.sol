// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./RTC.sol";
contract STAKING  {
    RTC public stakingToken;
    uint256 interestPerSecond;
    uint256 stakedAmount;
    uint256 secInMonth = 30 * 24 * 60 * 60 ;
    uint256 rewardGeneratedFor;
    uint256 stakePerWEEK;
    uint256 weekOfClaim;
    uint256 timeAfterStakeFinish;
    uint256 totalclaimAvailable;
    uint256 index = 0;
  
    //stakedmonth will be of 360 days = 360  * 24 * 60 * 60 = 3,11,04,000 sec
    // month will be of 30 days = 30 * 24 * 60 * 60 = 25,92,000 sec
    // week = 7 days = 7 * 24 * 60 * 60 = 6,04,800 sec
     
    mapping(address => mapping(uint256 => uint256)) _stakeMonth;
    mapping(address => mapping(uint256 => uint256)) _stakedMoney;
    mapping(address => mapping(uint256 => uint256)) totalClaim;
    mapping(address => mapping(uint256 => uint256)) TotalReward;
    mapping(address => mapping(uint256 => uint256)) claimableReward;
    mapping(address => mapping(uint256 => uint256)) staketime;
    mapping(address => mapping(uint256 => uint256)) coolingTime;

    // enter the token's address you want to stake
    constructor(address _stakingToken) {
        stakingToken = RTC(_stakingToken);
    }

    // enter amount ,month , and interest according the given condition
    // it deduct the entered amount and add to totalsupply of contract
    //generate a unique id for every stake

    function stake(
        uint256 amount ,
        uint256 months,
        uint256 interest
    ) public {
        require(
            (interest == 3 && months == 12) ||
                (interest == 4 && months ==24) ||
                (interest == 5 && months == 36) ||
                (interest == 6 && months == 60),
            "Invalid Input"
        );
        require(amount >= 100 * 10**9, "minimum stake is 100");
        // generate new ID everytime you stake
        index = index + 1;
       
        stakedAmount += amount;
        _stakeMonth[msg.sender][index] = months;
        staketime[msg.sender][index] = block.timestamp;
        coolingTime[msg.sender][index] =
            staketime[msg.sender][index] +
            _stakeMonth[msg.sender][index] *
            secInMonth;
        _stakedMoney[msg.sender][index] = amount;
        //transferStake balance from user to smart contract
        RTC(stakingToken).transferStake(msg.sender, address(this), amount);

        //calculate total reward of time period
        TotalReward[msg.sender][index] = (((interest *
            _stakedMoney[msg.sender][index]) * _stakeMonth[msg.sender][index]) /
            100);
             interestPerSecond =
                TotalReward[msg.sender][index] /
                (_stakeMonth[msg.sender][index] * secInMonth);
        emit staked(
            index,
            _stakedMoney[msg.sender][index],
            staketime[msg.sender][index],
            _stakeMonth[msg.sender][index],
            TotalReward[msg.sender][index]
        );
    }

    // enter the uniqueID generated while staking to access that particular stake
    function indexid(uint256 _index) public {
        require(stakedAmount > 0, "  stake some amonut");
        index = _index;
        require(_index <= index, "First, stake some amount");
        _stakedMoney[msg.sender][index];
        emit indexID(
            index,
            _stakedMoney[msg.sender][_index],
            _stakeMonth[msg.sender][index]
        );
    }

    // reward generation till cooling period
    function rewardGen() public {
        require(stakedAmount > 0, "  stake some amonut");
        //before staketime over
        //reward generation start when you stake some money
        //first time reward generated - reward generate of the fixed timed duration  from staking time to current time
        // reward generate of the fixed timed duration  from last claim time to current time
        if (coolingTime[msg.sender][index] > block.timestamp) {
           
            uint256 RewardTime = block.timestamp - staketime[msg.sender][index];
            claimableReward[msg.sender][index] = RewardTime * interestPerSecond;
            claimableReward[msg.sender][index] =
                claimableReward[msg.sender][index] -
                totalClaim[msg.sender][index];
            rewardGeneratedFor =
                claimableReward[msg.sender][index] /
                interestPerSecond;
            emit RewardGen(
                index,
                interestPerSecond,
                RewardTime,
                claimableReward[msg.sender][index],
                rewardGeneratedFor
            );
        }
        // after staketime over
        // reward generate of fixed timed duration  from last claim time to cooling time
        else if (
            coolingTime[msg.sender][index] < block.timestamp &&
            TotalReward[msg.sender][index] != 0
        ) {
            interestPerSecond =
                 TotalReward[msg.sender][index] /
                (_stakeMonth[msg.sender][index] * secInMonth);
               
            uint256 RewardTime = block.timestamp - staketime[msg.sender][index];
            RewardTime = _stakeMonth[msg.sender][index] * secInMonth;
            claimableReward[msg.sender][index] =
                TotalReward[msg.sender][index] -
                totalClaim[msg.sender][index];
            rewardGeneratedFor =
                _stakeMonth[msg.sender][index] *
                secInMonth -
                totalClaim[msg.sender][index] /
                interestPerSecond;
            emit RewardGen(
                index,
                interestPerSecond,
                RewardTime,
                claimableReward[msg.sender][index],
                rewardGeneratedFor
            );
        }
        //claim principle
        //first claim all reward before claiming principle
        //claim will be generated weekly
        else if (
            coolingTime[msg.sender][index] < block.timestamp &&
            TotalReward[msg.sender][index] == 0
        ) {
            require(
                coolingTime[msg.sender][index] + 604800 < block.timestamp,
                "Can only generate after cooling Time"
            );
            stakePerWEEK = _stakedMoney[msg.sender][index] / 604800;
            timeAfterStakeFinish =
                block.timestamp -
                coolingTime[msg.sender][index];
            weekOfClaim = timeAfterStakeFinish / 20;
            //before 20 weeks time duration
            if (weekOfClaim < 20) {
                totalclaimAvailable = weekOfClaim * stakePerWEEK;
                claimableReward[msg.sender][index] =
                    totalclaimAvailable -
                    totalClaim[msg.sender][index];
                emit Withdrawl(
                    index,
                    stakePerWEEK,
                    weekOfClaim,
                    claimableReward[msg.sender][index],
                    totalClaim[msg.sender][index],
                    _stakedMoney[msg.sender][index]
                );
            }
            //after 20 weeks claim period finish
            else {
                weekOfClaim = _stakedMoney[msg.sender][index] / stakePerWEEK;
                totalclaimAvailable = _stakedMoney[msg.sender][index];
                claimableReward[msg.sender][index] =
                    _stakedMoney[msg.sender][index] -
                    totalClaim[msg.sender][index];
                emit Withdrawl(
                    index,
                    stakePerWEEK,
                    weekOfClaim,
                    claimableReward[msg.sender][index],
                    totalClaim[msg.sender][index],
                    _stakedMoney[msg.sender][index]
                );
            }
        }
    }

    // claiming reward generated by rewardGen() function
    // we need to generate reward by rewardGen() function
    function claimReward() public {
        require(stakedAmount > 0, "  stake some amonut");
        //before staketime over
        //claimed reward will add in a mapping
        // amount generated by rewardGen() function will be mint to user.
        if (block.timestamp < coolingTime[msg.sender][index]) {
            totalClaim[msg.sender][index] =
                claimableReward[msg.sender][index] +
                totalClaim[msg.sender][index];
              RTC(stakingToken)._mint(msg.sender, claimableReward[msg.sender][index]);
            //after staketime over
            // amount generated by rewardGen() function will be mint to user.
        } else if (
            coolingTime[msg.sender][index] < block.timestamp &&
            TotalReward[msg.sender][index] != 0
        ) {
            TotalReward[msg.sender][index] -= TotalReward[msg.sender][index];
            totalClaim[msg.sender][index] -= totalClaim[msg.sender][index];
              RTC(stakingToken)._mint(msg.sender, claimableReward[msg.sender][index]);
        }
        //for claiming the stakedamount
        // Check StakeAmount Availibilty to claim
        // stakedamount will available and claimed weekly .
        else {
            require(
                claimableReward[msg.sender][index] > 0,
                "cant claim before mature amount"
            );
            //Stakeamount will transferStake from smaRTCotract address to user.
             RTC(stakingToken).transferStake(
                address(this),
                msg.sender,
                claimableReward[msg.sender][index]
            );
            totalClaim[msg.sender][index] =
                claimableReward[msg.sender][index] +
                totalClaim[msg.sender][index];
            stakedAmount -= claimableReward[msg.sender][index];
            claimableReward[msg.sender][index] -= claimableReward[msg.sender][
                index
            ];
            _stakedMoney[msg.sender][index] -= totalClaim[msg.sender][index];
        }
    }

    // ckecking current amount generated by rewardgen() function
    function ClaimAvailable() public view returns (uint256) {
        return claimableReward[msg.sender][index];
    }

    // total supply of the staked contract
    function totalSupply() public view virtual  returns (uint256) {
        return stakedAmount;
    }
function balanceOF_(address addr ) public view returns(uint){
    return   RTC(stakingToken).balanceOf(addr);
}
    // for selecting the ID which you want to check detail .
    function getApplicationByBATCHID(uint256 _index)
        public
        view
        returns (
          
            uint256 stakedtime,
            uint256 stakedmoney,
            uint256 stakeMonth,
            uint256 TotalClaim,
            uint256 totalRewardGenerated,
            uint256 Coolingtime
        )
    {
        return (
          
            staketime[msg.sender][_index],
            _stakedMoney[msg.sender][_index],
            _stakeMonth[msg.sender][_index],
            totalClaim[msg.sender][_index],
            TotalReward[msg.sender][_index],
            coolingTime[msg.sender][_index]
        );
    }

    event staked(
        uint256 id,
        uint256 stakedAmount,
        uint256 StakeTime,
        uint256 _stakeMonth,
        uint256 totalRewardGeneratead
    );
    event indexID(
        uint256 indexID,
        uint256 stakedMoneyONID,
        uint256 stakedMonthOfID
    );
    event RewardGen(
        uint256 id,
        uint256 interestPerSecond,
        uint256 rewardGeneratedPeriod,
        uint256 RewardGeneratedAmount,
        uint256 rewardGeneratedFor
    );
    event Withdrawl(
        uint256 id,
        uint256 stakePerWEEK,
        uint256 totalWeekOfWithdrawlGenerated,
        uint256 rewardAvailable,
        uint256 totalclaimed,
        uint256 stakedAmount
    );
}
