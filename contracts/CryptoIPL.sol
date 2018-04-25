pragma solidity ^0.4.18;

import "./ERC721.sol";
import "./SafeMath.sol";
/// @title CryptoIPL an Ethereum game, based on ERC721 Non Fungible token..
/// @author Dheeraj Pal pdheeraj368@gmail.com.
/// @notice This is IPL game for crypto enthusiast.
contract CryptoIPL is ERC721 {
    
    /*** LIBRARIES ***/
    /// SafeMath for secure calculation purpose.
    using SafeMath for uint256;
    
    
    /*** EVENTS ***/
    // Events can be captured to notify.
    
    /// @dev Intro event: fired when new participant indroduced.
    event Intro(uint256 tokenId, string name, address owner);
    
    /// @dev TokenSold event: fired when token is sold.
    event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address oldOwner, address newOwner, string name);
    
    /// @dev Transfer event: defined is the current draft of ERC721.
    /// ownership is assigned including owner.
    event Transfer(address from, address to, uint256 tokenId);
    
    /*** CONSTANTS ***/
    /// Constants to be used for Dapp.
    
    /// @notice Name and Symbol of the non fungible token as per ERC721.
    string public constant NAME = "CryptoIPL";
    string public constant SYMBOL = "IPLToken";
    
    uint256 private startingPrice = 0.002 ether;
    uint256 private constant PROMO_CREATION_LIMIT = 1000;
    uint256 private firstStepLimit = 0.07 ether;
    uint256 private secondStepLimit = 0.3 ether;
    
    /*** STORAGE ***/
    /// State variale to be used for the Dapp.
    
    /// @dev : mapping from IPL participant to its owner.
    mapping (uint256 => address) public participantToOwner;
    
    /// @dev : mapping from address to count to IPL participant it owns.
    /// used internally for balanceOf().
    mapping (address => uint256) public ownershipTokenCount;
    
    /// @dev : mapping from participant to Owner who is authorised to call
    /// transferFrom(). each participant can have only one approved address
    /// at a time.
    mapping(uint256 => address) public participantToApproved;
    
    /// @dev : mapping from participant to selling price.
    mapping(uint256 => uint256) private participantToPrice;
    
    
    /// address of the accounts that can execute actions within roles.
    address public ceoAddress;
    address public cooAddress;
    
    
    uint256 public createdPromoCount;
    
    /*** DATATYPES ***/
    /// Datatypes to be used for Dapp.
    
    /// IPL participant.
    struct Participant {
        string name;
    }
    
    /// @dev: Array list of all the participant.
    Participant[] private participants;
    
    /*** ACCESS MODIFIERS ***/
    /// Modifiers to be user for Dapp.
    
    /// @dev : Modifier for CEO only functionality.
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }
    
    /// @dev : Modifier for COO only functionality.
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }
    
    /*** CONSTRUCTER ***/
    
    function CryptoIPL() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
    }
    
    /*** PUBLIC FUNCTIONS ***/
    
    /// @notice : function to grant other address authority to use transferOwnership() and transferFrom().
    /// @param _to : address to which permission is being given.
    /// @param _tokenId : participant token Id.
    /// @dev : as per ERC721 complience.
    function approve(
        address _to,
        uint256 _tokenId
    ) public {
        // caller must own the token.
        require(msg.sender == participantToOwner[_tokenId]);
            
        participantToApproved[_tokenId] = _to;
            
        // fire approve event.
        emit Approval(msg.sender, _to, _tokenId);
    }
        
    /// @notice : get the balance of an address.
    /// @param _owner : address.
    /// @dev : required for ERC721 complience.
    function balanceOf (
        address _owner    
    ) public view returns (uint256 balance) {
        return ownershipTokenCount[_owner];
    }
    
    /// @dev : creates a new promo participant with a given name, price and assign it to an address.
    function createPromoParticipant(
        string _name,
        uint256 _price,
        address _owner
    ) public onlyCOO {
        
        require(createdPromoCount < PROMO_CREATION_LIMIT);
        
        address participantOwner = _owner;
        
        if(participantOwner == address(0)) {
            participantOwner = cooAddress;
        }
        
        if(_price <= 0) {
            _price = startingPrice;
        }
        
        createdPromoCount++;
        
        // function to create participant.
        _createParticipant(_name, _price, _owner);
    }
    
    /// @dev : create participant with the given name.
    function createContractParticipant(
        string _name    
    ) public onlyCOO {
        _createParticipant(_name, startingPrice, address(this));
    }
    
    /// @notice : return all the relevant information about a given participant.
    /// @param _tokenId : participantId.
    function getParticipant(
        uint256 _tokenId    
    ) public view returns (
        string participantName,
        uint256 sellingPrice,
        address owner
    ) {
        
        Participant storage _participant = participants[_tokenId];
        participantName = _participant.name;
        sellingPrice = participantToPrice[_tokenId];
        owner = participantToOwner[_tokenId];
    }
    
    function implementsERC721() public pure returns (bool) {
        return true;
    }
    
    /// @dev : required for ERC721 complience.
    function name() public pure returns (string) {
        return NAME;
    }
    
    /// For querying owner of the participant.
    /// @param _tokenId : participantId.
    /// @dev Required for ERC721 participant.
    function ownerOf (
        uint256 _tokenId    
    ) public view returns (
        address owner
    ) {
        owner = participantToOwner[_tokenId];
        require(owner != address(0));
    }
    
    
    function payout (
        address _to
    ) public onlyCEO {
        _payout(_to);
    }
    
    /// Allow someone to send some ether and own the participant.
    /// #param _tokenId : participant id.
    function purchase (
        uint256 _tokenId    
    ) public payable {
        
        address oldOwner = participantToOwner[_tokenId];
        address newOwner = msg.sender;
        
        // current selling price of participant.
        uint256 sellingPrice = participantToPrice[_tokenId];
        
        // making sure the owner not selling itself.
        require(oldOwner != newOwner);
        
        // safety check to prevent unexpected 0*0 default.
        require(_addressNotNull(newOwner));
        
        // making sure the price is greater than the selling price.
        require(msg.value >= sellingPrice);
        
        uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 94), 100));
        uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
        
        // update price.
        if (sellingPrice < firstStepLimit) {
            // price increase for first stage.
            participantToPrice[_tokenId] = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 200), 94));
        } else if (sellingPrice < secondStepLimit) {
            //price increase for the second stage.
            participantToPrice[_tokenId] = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 120), 94));
        } else {
            // price increase for the third stage.
            participantToPrice[_tokenId] = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 115), 94));
        }
        
        _transfer(oldOwner, newOwner, _tokenId);
        
        // pay previous owner if its not contract.
        if (oldOwner != address(this)) {
            oldOwner.transfer(payment);// 1-0.06
        }
        
        // fire token sold event.
        emit TokenSold(_tokenId, sellingPrice, participantToPrice[_tokenId], oldOwner, newOwner, participants[_tokenId].name);
        
        msg.sender.transfer(purchaseExcess);        
        
    }
    
    /// @notice : get price of a participant.
    /// @param _tokenId : participant id.
    function priceOf(
        uint256 _tokenId    
    ) public view returns (uint256) {
        return participantToPrice[_tokenId];
    }
    
    /// @dev : assign a new ceo.
    /// @param _newCEO : address.
    function setCEO (
        address _newCEO    
    ) public onlyCEO {
        ceoAddress = _newCEO;
    }
    
    /// @dev : assign a new COO.
    /// @param _newCOO : address.
    function setCOO (
        address _newCOO    
    ) public onlyCOO {
        cooAddress = _newCOO;
    }
    
    /// @dev : required for ERC721 complience.
    function symbol() public pure returns (string) {
        return SYMBOL;
    }
    
    /// @notice : allowed a pre approved token to take ownership of a token.
    /// @param _tokenId : participant id.
    /// @dev : required for ERC721 complience.
    function takeOwnership(
        uint256 _tokenId    
    ) public {
        
        address oldOwner = participantToOwner[_tokenId];
        address newOwner = msg.sender;
        
        // safety check to prevent against 0*0 defualt.
        require(_addressNotNull(newOwner));
        
        // makng sure the transfer is approved.
        require(_approved(newOwner, _tokenId));
        
        _transfer(oldOwner, newOwner, _tokenId);
    }
    
    /// @param _owner : address.
    /// @dev : this method must not be called by contract, its fairely expensive
    /// second it returns dynamic array which is for web3 calls.
    function tokensOfOwner(
        address _owner
    ) public view returns (
        uint256[] ownerTokens
    ) {
        
        uint256 tokenCount = balanceOf(_owner);
        if(tokenCount == 0) {
            // return an empty array.
            return new uint256[](0);
        } else {
            
            uint256[] memory result  = new uint256[](tokenCount);
            //uint256[] memory result  = new uint256[](2);
            uint256 totalParticipants = totalSupply();
            uint256 resultIndex = 0;
            uint256 participantId;
            for (participantId = 0; participantId <= totalParticipants; participantId++) {
                if(participantToOwner[participantId] == _owner) {
                    result[resultIndex] = participantId;
                    resultIndex++;
                }
            }
            
            return result;
        }
    }
    
    
    /// querying total supply of tokens.
    /// required for ERC721 complience.
    function totalSupply() public view returns (uint256 total) {
        total = participants.length;
    }
    
    /// owner initiate the transfer of token to other account.
    /// @param _to : address for the token to be transfered to.
    /// @param _tokenId : participant id.
    /// @dev : required for ERC721 complience.
    function transfer(
        address _to,
        uint256 _tokenId
    ) public {
        
        require(_owns(msg.sender, _tokenId));
        require(_addressNotNull(_to));
        
        _transfer(msg.sender, _to, _tokenId);
    }
    
    
    /// @notice : third party initialte the transfer of token.
    /// @param _from : address from which transfer has to be done.
    /// @param _to : address to which the transfer has to be done.
    /// @dev : required for ERC721 complience.
    function transferFrom (
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        
        require(_owns(_from, _tokenId));
        require(_approved(_to, _tokenId));
        require(_addressNotNull(_to));
        
        _transfer(_from, _to, _tokenId);
        
    }
    
    /*** PRIVATE FUNCTIONS ***/
    /// private functions to be user for Dapp.
    
    /// safety function to check if address is null or not.
    function _addressNotNull(
        address _to
    ) private pure returns (bool) {
        return _to != address(0);
    }
    
    /// for checking the approval of transfer for address to participant.
    function _approved (
        address _to, 
        uint256 _tokenId
    ) private view returns (bool) {
        return participantToApproved[_tokenId] == _to;
    }
    
    
    /// @dev : for craeting participant.
    function _createParticipant(
        string _name,
        uint256 _price,
        address _owner
    ) private {
        
        // create memory variable for new participant.
        Participant memory _participant = Participant({
            name: _name
        });
        
        // getting the id of participant.
        uint256 _participantId = participants.push(_participant) -1;
        
        // Its never going to happen for 4 billion participant.
        // but let's just check to be 100% sure.
        require(_participantId == uint256(uint32(_participantId)));
        
        // fire birth event.
        emit Intro(_participantId, _name, _owner);
        
        participantToPrice[_participantId] = _price;
        
        // this will assign ownership and also emit transfer event.
        // as per ERC721 complience.
        _transfer(address(0), _owner, _participantId);
    }
    
    /// checking for token ownership.
    function _owns(
        address _claimant,
        uint256 _tokenId
    ) private view returns (bool) {
        return _claimant == participantToOwner[_tokenId];
    }
    
    /// for paying out the balance of the contract.
    function _payout (
        address _to    
    ) private {
        address contractAddress = this;
        if(_to == address(0)) {
            ceoAddress.transfer(contractAddress.balance);
        } else {
            _to.transfer(contractAddress.balance);
        }
    }
    
    /// assign ownership f a participant to an address.
    function _transfer (
        address _from,
        address _to,
        uint256 _tokenId
    ) private {
        // since the number of partcipant is capped we can't overflow this.
        ownershipTokenCount[_to]++;
        
        //transfer ownership.
        participantToOwner[_tokenId] = _to;
        
        // when crated new address it was from 0*0 need to delete.
        if(_from != address(0)) {
            ownershipTokenCount[_from]--;
            // clear the approved ownership as well.
            delete participantToApproved[_tokenId];
        }
        
        // emit event for new participant transfer.
        emit Transfer(_from, _to, _tokenId);
    }
    
}