// SPDX-License-Identifier: MIT
// File: contracts/ContractManagerInterface.sol

pragma solidity ^0.8.0;

abstract contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    
    // mo meed to specfy internal in constructor as contract is abstract 
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     *
     * not an internal constructor
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract STAKING2 is Ownable {
    RTC public stakingToken;
    // for checking staked amount

    // mapping(address => uint256[]) private Amount;
    // amount lockTime period
    // mapping(address => uint256[]) private lockTime;
    //amount total staked by user
    mapping(address => uint256) private totallock;
    // total staked on contract
    uint256 private totalStaked;
    //detail of the staker
    mapping(address => stakeDetail) public _stakeDetail;
    //total amount available to claim
    mapping(address => uint256) private AvailableForClaim;
    // time after user unstakeAmount to check claim time is over or not
    mapping(address => uint256) public _coolingTime;
    //total unstaked amount
    mapping(address => uint256) public totalAmountClaimed;

    address[] public details;
    bool exist = true;
    uint256 indexID;
    // lockTime period default 1 year
    //  60 * 60 * 24 * 365 = 31536000 sec
    uint256 _lockTimePeriod = 120;
    // lockTime period default 1 week
    // 60 * 60 * 24 * 7 =604800 sec
    uint256 coolingTime = 60;
    //primary wallet where all amount transfer
    address primaryWallet;
    struct stakeDetail {
        uint256 numberOfStake;
        address userAddr;
        mapping(address => uint256[]) stakedTokens;
        mapping(address => uint256[]) lockedTime;
        uint256 totalStaked;
    }

    constructor(address _stakeToken, address _primaryWallet) {
        stakingToken = RTC(_stakeToken);
        primaryWallet = _primaryWallet;
    }

    // staking
    function stake(uint256 _amount) public {
        //check user balance
        //transfer amount to primary wallet
        RTC(stakingToken).transferPrice(msg.sender, primaryWallet, _amount);
        //calculate total amount staked in contract
        totalStaked += _amount;
        //amount lockTimeed by user
        totallock[msg.sender] += _amount;
        uint256 lockTimePeriod = block.timestamp + _lockTimePeriod;
        _stakeDetail[msg.sender].numberOfStake += 1;
        _stakeDetail[msg.sender].userAddr = msg.sender;
        _stakeDetail[msg.sender].stakedTokens[msg.sender].push(_amount);
        _stakeDetail[msg.sender].lockedTime[msg.sender].push(lockTimePeriod);
        _stakeDetail[msg.sender].totalStaked = totallock[msg.sender];
        details.push(msg.sender);
        emit _stake(
            msg.sender,
            _stakeDetail[msg.sender].numberOfStake,
            _amount,
            lockTimePeriod
        );
    }

    event _stake(
        address stakerAddr,
        uint256 totalNumberOfStake,
        uint256 amount,
        uint256 AmountlockTill
    );

    // work after lockperiod is over
    // claim only amount which lock period is over
    function Unstake() public {
        require(
            totallock[msg.sender] != totalAmountClaimed[msg.sender],
            "no amount staked"
        );
        for (
            uint256 i = 0;
            i < _stakeDetail[msg.sender].lockedTime[msg.sender].length;
            i++
        ) {
            if (
                _stakeDetail[msg.sender].lockedTime[msg.sender][i] <
                block.timestamp
            ) {
                AvailableForClaim[msg.sender] += _stakeDetail[msg.sender]
                    .stakedTokens[msg.sender][i];
                _stakeDetail[msg.sender].stakedTokens[msg.sender][i] = 0;
                _coolingTime[msg.sender] = block.timestamp + coolingTime;
                _stakeDetail[msg.sender].stakedTokens[msg.sender][i] = 0;
                _stakeDetail[msg.sender].lockedTime[msg.sender][i] = 0;
            }
        }
        emit _Unstake(
            msg.sender,
            AvailableForClaim[msg.sender],
            totalAmountClaimed[msg.sender]
        );
    }

    event _Unstake(
        address stakerAddr,
        uint256 AmountUnlocked,
        uint256 previouslyClaimed
    ); 

    //amount ready to claim after cooling period
    function AmountUstaked(address addr) public view returns (uint256) {
        return AvailableForClaim[addr];
    }

    // claim mature amount after cooling period
    function Claim() public {
        //check if user has mature amount or not
        require(AvailableForClaim[msg.sender] > 0, "no money to claim ");
        // check if cooling time is over
        require(
            _coolingTime[msg.sender] < block.timestamp,
            "cooling time not over "
        );
        // transfer amount primary wallet to user
        RTC(stakingToken).transferPrice(
            primaryWallet,
            msg.sender,
            AvailableForClaim[msg.sender]
        );

        totalAmountClaimed[msg.sender] += AvailableForClaim[msg.sender];
        AvailableForClaim[msg.sender] -= AvailableForClaim[msg.sender];
          _coolingTime[msg.sender] =0;
        emit _claim(
            msg.sender,
            AvailableForClaim[msg.sender],
            totalAmountClaimed[msg.sender],
            totallock[msg.sender]
        );
    }

    event _claim(
        address stakerAddr,
        uint256 AvailableForClaim,
        uint256 totalAmountClaimed,
        uint256 totallockOfUser
    );

    // for changing the primary wallet
    //only owner can
    function setPrimaryWallet(address walletAddress) public onlyOwner {
        primaryWallet = walletAddress;
    }

    // get the primary wallet where all amount staked
    function getPrimaryWallet() public view returns (address) {
        return primaryWallet;
    }

    //check if caller is owner return true/false
    function isStaker(address addr ) public view returns (bool) {
        for (uint256 i; i < details.length; i++) {
            if (details[i] == addr ) return exist;
        }
    }

    // total amount staked by the user
    function UserTotallockAmount(address addr ) public view returns (uint256) {
        return totallock[addr];
    }

    //set cooling time only by owner
    function setCoolingTime(uint256 CoolingTime) public onlyOwner {
        coolingTime = CoolingTime;
    }

    //additional time after unlockTime token
    function getCoolingTime() public view returns (uint256) {
        return coolingTime;
    }

    //set cooling time only by owner
    function setlockTimePeriod(uint256 lockTimePeriod) public onlyOwner {
        _lockTimePeriod = lockTimePeriod;
    }

    //additional time after unlockTime token
    function getlockTimePeriod() public view returns (uint256) {
        return _lockTimePeriod;
    }

    // check available balance
    function myBalance(address addr) public view returns (uint256) {
        return RTC(stakingToken).balanceOf(addr );
    }

    // total amount stakwed on contract
    function _totalStaked() public view returns (uint256) {
        return totalStaked;
    }

    //showing amount and lock time of the caller
    function DetailOfStake(address addr)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        return (
            _stakeDetail[addr].stakedTokens[addr],
            _stakeDetail[addr].lockedTime[addr]
        );
    }
}
