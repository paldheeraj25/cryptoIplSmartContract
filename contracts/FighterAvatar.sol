pragma solidity ^0.4.19;
import "./Ownable.sol";

contract FighterAvatar is Ownable {
    
    uint fighterSkill = 16;
    uint fighterSkillModulus = 10 ** 16;
    uint cooldDownTimer = 1 days;
    struct Fighter {
        string name;
        uint skill;
        uint32 level;
        uint32 readyTime;
        uint16 winCount;
        uint16 lossCount;
    }
    
    Fighter[] public fighters;
    
    mapping (uint => address) public fighterToOwner;
    mapping (address => uint) ownerFighterCount;
    
    function _createFighter(string _name, uint _skill) internal {
        uint id = fighters.push(Fighter(_name, _skill, 1, uint32(now + cooldDownTimer), 0, 0)) - 1;
        fighterToOwner[id] = msg.sender;
        ownerFighterCount[msg.sender]++;
    }
    
    function _generateRandomSkill(string _name) private view returns(uint) {
        uint skill = uint(keccak256(_name));
        return skill % fighterSkillModulus ;
    } 
    
    function generateRandomFighter(string _name) public {
        require(ownerFighterCount[msg.sender] == 0);
        uint randomSkill = _generateRandomSkill(_name);
        _createFighter(_name, randomSkill);
    }
}