pragma solidity ^0.6.6;


// import "https://raw.githubusercontent.com/smartcontractkit/chainlink/master/contracts/src/v0.6/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase {
    enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING_WINNER }
    LOTTERY_STATE public lottery_state;
    address payable[] public players;
    uint startTime;
    address admin;

    uint256 internal fee;
    uint256 public randomResult;
    
    //Network: Rinkeby
    address constant VFRC_address = 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B; // VRF Coordinator
    address constant LINK_address = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709; // LINK token
    bytes32 constant internal keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;

    constructor() VRFConsumerBase(VFRC_address, LINK_address) public {
        fee = 0.1 * 10 ** 18; // 0.1 LINK
        admin = msg.sender;
        lottery_state = LOTTERY_STATE.CLOSED;
    }
    
    modifier adminOnly(){
        require(msg.sender == admin, "Access denied!");
        _;
    }
    
    modifier notAdmin(){
        require(msg.sender != admin, "Access denied");
        _;
    }

    modifier onlyVFRC() {
        require(msg.sender == VFRC_address, 'only VFRC can call this function');
        _;
    }
    
    function start_new_lottery() public adminOnly{
        require(lottery_state == LOTTERY_STATE.CLOSED, "another lottery open");
        startTime = now;
        lottery_state = LOTTERY_STATE.OPEN;
    }   

    function getWinner() public adminOnly{
        if(now - startTime >= 3600){
            lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        }
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You need to wait");
        getRandomNumber();
        pickWinner();
    }

    function enter() public payable notAdmin{

        assert(now - startTime <= 3600);
        assert(msg.value == 0.1 ether);
        assert(lottery_state == LOTTERY_STATE.OPEN);
        players.push(msg.sender);
    }

    function getRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) > fee, "Error, not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }

    function pickWinner() public{
        uint256 index = randomResult % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
    }
}