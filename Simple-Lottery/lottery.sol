// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleLottery {
    address public owner;
    address[] public players;
    uint256 public lotteryId;
    uint256 public entryFee;
    bool public isLotteryActive;
    
    mapping(uint256 => address) public lotteryHistory;
    
    event PlayerEntered(address player, uint256 lotteryId);
    event WinnerSelected(address winner, uint256 prize, uint256 lotteryId);
    event LotteryStarted(uint256 lotteryId, uint256 entryFee);
    event LotteryEnded(uint256 lotteryId);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier lotteryIsActive() {
        require(isLotteryActive, "Lottery is not active");
        _;
    }
    
    constructor(uint256 _entryFee) {
        owner = msg.sender;
        entryFee = _entryFee;
        lotteryId = 1;
        isLotteryActive = true;
        emit LotteryStarted(lotteryId, entryFee);
    }
    
    // Function 1: Enter the lottery
    function enterLottery() public payable lotteryIsActive {
        require(msg.value == entryFee, "Incorrect entry fee");
        require(msg.sender != owner, "Owner cannot participate");
        
        // Check if player already entered
        for (uint256 i = 0; i < players.length; i++) {
            require(players[i] != msg.sender, "Player already entered");
        }
        
        players.push(msg.sender);
        emit PlayerEntered(msg.sender, lotteryId);
    }
    
    // Function 2: Select winner randomly
    function selectWinner() public onlyOwner lotteryIsActive {
        require(players.length >= 2, "Need at least 2 players");
        
        uint256 randomIndex = getRandomNumber() % players.length;
        address winner = players[randomIndex];
        uint256 prize = address(this).balance;
        
        // Transfer prize to winner
        payable(winner).transfer(prize);
        
        // Store winner in history
        lotteryHistory[lotteryId] = winner;
        
        emit WinnerSelected(winner, prize, lotteryId);
        emit LotteryEnded(lotteryId);
        
        // Reset for next lottery
        resetLottery();
    }
    
    // Function 3: Get current lottery info
    function getLotteryInfo() public view returns (
        uint256 currentLotteryId,
        uint256 playerCount,
        uint256 prizePool,
        uint256 ticketPrice,
        bool active
    ) {
        return (
            lotteryId,
            players.length,
            address(this).balance,
            entryFee,
            isLotteryActive
        );
    }
    
    // Function 4: Get players list
    function getPlayers() public view returns (address[] memory) {
        return players;
    }
    
    // Function 5: Get lottery winner by ID
    function getLotteryWinner(uint256 _lotteryId) public view returns (address) {
        return lotteryHistory[_lotteryId];
    }
    
    // Internal function to generate pseudo-random number
    function getRandomNumber() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            players.length,
            msg.sender
        )));
    }
    
    // Internal function to reset lottery state
    function resetLottery() private {
        delete players;
        lotteryId++;
        isLotteryActive = true;
        emit LotteryStarted(lotteryId, entryFee);
    }
    
    // Owner function to pause/resume lottery
    function toggleLottery() public onlyOwner {
        isLotteryActive = !isLotteryActive;
    }
    
    // Owner function to change entry fee (only when lottery is inactive)
    function changeEntryFee(uint256 _newFee) public onlyOwner {
        require(!isLotteryActive, "Cannot change fee while lottery is active");
        entryFee = _newFee;
    }
}
