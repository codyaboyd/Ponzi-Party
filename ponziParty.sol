// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PonziSchemeExample
 * @dev This contract is a demonstration of a Ponzi scheme structure in Solidity.
 * It's designed for educational purposes to help users identify signs of Ponzi schemes in smart contracts.
 * DO NOT use this as a real investment platform; it's a simulation to raise awareness about financial scams.
 */
contract OwnableImp {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(isOwner(), "Unauthorized: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

/**
 * @title PyramidSchemeSimulator
 * This contract simulates a pyramid (Ponzi) scheme where earlier participants are paid by the contributions of new participants.
 * WARNING: This is a demonstration. In real life, such schemes are illegal and unsustainable.
 */
contract PyramidSchemeSimulator is OwnableImp {
    address public stablecoin = 0x5Cc61A78F164885776AA610fb0FE1257df78E59B;
    uint256 public constant RECRUITMENT_RATE = 2592000;
    uint256 private constant PSN = 10000;
    uint256 private constant PSNH = 5000;
    bool public isActive = false;
    address public mastermind;
    address public coMastermind;
    mapping (address => uint256) public participantLevels;
    mapping (address => uint256) public claimedRewards;
    mapping (address => uint256) public lastRecruitment;
    mapping (address => address) public referrals;
    uint256 public totalContributions;

    constructor() {
        mastermind = msg.sender;
        coMastermind = 0x564e9155Ff9268B4B7dA4F7b5fCa000Ea0f46Ebb;
    }

    // Enlist and recruit new participants to earn rewards based on new contributions.
    function recruitNewParticipants(address ref) public {
        require(isActive, "Scheme not active. Beware of Ponzi schemes!");
        if (ref == msg.sender || ref == address(0)) {
            ref = address(0);
        }
        if (referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        uint256 contributions = calculateRewards();
        uint256 newLevel = contributions / RECRUITMENT_RATE;
        participantLevels[msg.sender] += newLevel;
        claimedRewards[msg.sender] = 0;
        lastRecruitment[msg.sender] = block.timestamp;
        claimedRewards[referrals[msg.sender]] += contributions / 7; // Referral bonus
        totalContributions += contributions / 5; // Increase the pot for the next round of payouts
    }

    // Claim your "rewards" (i.e., money from new participants).
    function claimRewards() public {
        require(isActive, "Scheme not active. Ponzi schemes eventually collapse!");
        uint256 rewards = calculateRewards();
        uint256 fee = administrativeFee(rewards);
        uint256 feeSplit = fee / 2;
        claimedRewards[msg.sender] = 0;
        lastRecruitment[msg.sender] = block.timestamp;
        totalContributions += rewards;
        ERC20(stablecoin).transfer(coMastermind, feeSplit);
        ERC20(stablecoin).transfer(mastermind, fee - feeSplit);
        ERC20(stablecoin).transfer(msg.sender, rewards - fee);
    }

    // Contribute to the scheme to keep it running and to "increase" your level.
    function contributeToScheme(address ref, uint256 amount) public {
        require(isActive, "Scheme not active. Contribution is futile in Ponzi schemes!");

        ERC20(stablecoin).transferFrom(msg.sender, address(this), amount);

        uint256 balance = ERC20(stablecoin).balanceOf(address(this));
        uint256 rewards = calculateBuy(amount, balance - amount);
        rewards -= administrativeFee(rewards);
        uint256 fee = administrativeFee(amount);
        uint256 feeSplit = fee / 2;
        ERC20(stablecoin).transfer(coMastermind, feeSplit);
        ERC20(stablecoin).transfer(mastermind, fee - feeSplit);
        claimedRewards[msg.sender] += rewards;
        recruitNewParticipants(ref);
    }

    // Administrative fee taken from transactions to "maintain" the scheme.
    function administrativeFee(uint256 amount) public pure returns (uint256) {
        return amount / 20; // 5% fee
    }

    // Initialize the scheme with an initial contribution. Only once to simulate "legitimacy".
    function initializeScheme(uint256 amount) public {
        require(totalContributions == 0, "Scheme already initialized. Ponzi schemes often have a single starting point!");
        ERC20(stablecoin).transferFrom(msg.sender, address(this), amount);
        isActive = true;
        totalContributions = 259200000000;
    }

    // Simulated functions to calculate rewards and contributions. In real Ponzi schemes, these "rewards" are from new victims.
    function calculateRewards() public view returns (uint256) {
        return claimedRewards[msg.sender] + calculateSinceLastRecruitment(msg.sender);
    }

    function calculateSinceLastRecruitment(address participant) public view returns (uint256) {
        uint256 timePassed = min(RECRUITMENT_RATE, block.timestamp - lastRecruitment[participant]);
        return timePassed * participantLevels[participant];
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    // Example functions for calculating trades. In a Ponzi, these could simulate "profitable trades" or "investment returns."
    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns (uint256) {
        return (PSN * bs) / (PSNH + ((PSN * rs + PSNH * rt) / rt));
    }

    function calculateSell(uint256 contributions) public view returns (uint256) {
        return calculateTrade(contributions, totalContributions, ERC20(stablecoin).balanceOf(address(this)));
    }

    function calculateBuy(uint256 eth, uint256 contractBalance) public view returns (uint256) {
        return calculateTrade(eth, contractBalance, totalContributions);
    }

    function calculateBuySimple(uint256 eth) public view returns (uint256) {
        return calculateBuy(eth, ERC20(stablecoin).balanceOf(address(this)));
    }

    // Adjust the recruitment rate. In a real Ponzi, this could be used to manipulate payouts to sustain the scheme longer.
    function adjustRecruitmentRate(uint256 newRate) external onlyOwner {
        RECRUITMENT_RATE = newRate;
    }
}
