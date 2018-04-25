pragma solidity ^0.4.19;

import "./FighterWar.sol";

contract FighterHelper is FighterWar {
    
    uint levelUpFee = 0.01 ether;
    
    modifier aboveLevel(uint _level, uint fighterId) {
        fighters[fighterId].level > _level;
        _;
    }
    
    function changeName(uint _fighterId, string _newName) public aboveLevel(_fighterId, 2) {
        fighters[_fighterId].name = _newName;        
    }
    
    function changeSkill(uint _fighterId, uint _newSKill) public aboveLevel(_fighterId, 20) {
        fighters[_fighterId].skill = _newSKill;        
    }
    
    
    function getFightersByOwner(address _owner) external view returns(uint[]) {
        uint[] memory result = new uint[](ownerFighterCount[_owner]);
        
        uint count = 0;
        for (uint i = 0 ; i < fighters.length ; i++) {
            
            if (fighterToOwner[i] == _owner) {
                result[count] = i;
                count++;
            }
        }
        
        return result;
    }
    
    function levelUp(uint _fighterId) public payable {
        require(msg.value == levelUpFee);
        fighters[_fighterId].level++;
    }
    
    function withdraw() external onlyOwner {
        owner.transfer(this.balance);
    }
    
    function changeLevelUpFee(uint _fee) external onlyOwner {
        levelUpFee = _fee;
    }
}