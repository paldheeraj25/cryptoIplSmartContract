pragma solidity ^0.4.19;

import "./FighterAvatar.sol"; 

contract kittyInterface  {
    function getKitty(uint256 _id) external view returns (
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256 genes
    );
}

contract FighterWar is FighterAvatar {

  // address of cryptokitties
  address ckAddress = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;

  kittyInterface myKitty = kittyInterface(ckAddress);

  function _triggerCoolDownFunction(Fighter storage myFighter) internal {
    myFighter.readyTimer = uitn32(now + 1 days);
  }

  function _isReady(FIghter storage myFighter) internal returns (bool) {
    return (myFighter.readyTimer < now);
  }

  function fightAndInclude(uint _fighterId, uint _skill) public {
    require(fighterToOwner[_fighterId] == msg.sender);
    Fighter storage myFighter = fighters[_fighterId];
    _skill = _skill % fighterSkillModulus;

    uint newSkill = (myFighter.skill + _skill) / 2;

    _createFighter("newFighter", newSkill);

  }

  function fightWithKitty(uint _fighterId, uint _kittyId) {
    uint kittySkill;
    ( , , , , , , , , , , kittySkill) = myKitty.getKitty(_kittyId);
    fightAndInclude(_fighterId, kittySkill);
  }

  function changeKittyContractAddress(address _address) public onlyOwner {
    ckAddress = _address;
  }
}