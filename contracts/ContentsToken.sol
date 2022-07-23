// SPDX-License-Identifier: GPL-3.0

/// @title The NounsMap contents ERC-721 token
/// https://dev.nounsmap.com/nft/
/// If you have a AuthorityToken you can mint  new contents from others.abi
/// NounsMap photos will be available for sale on market place.
/// For example, by distributing photos posted by people who have been affected by wars or disasters, 
/// we can directly support those who have been affected by the disaster. 
/// Please cooperate in NFT conversion of photos that you would like to support by carefully looking at the contents and explanations of the photos.",


/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;
import { Base64 } from 'base64-sol/base64.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { ERC721Checkpointable } from './base/ERC721Checkpointable.sol';
import { ERC721 } from './base/ERC721.sol';
import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { IProxyRegistry } from './external/opensea/IProxyRegistry.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

abstract contract AuthorityTokenInterface {
 function getCurrentVotes(address account) external virtual view returns (uint96); 
 //Note: following function also provided by AuthorityToken, but gas cost cannot predicted, so we avoid to use
 // function getPriorVotes(address account, uint256 blockNumber) public virtual view returns (uint96);
}

struct ContentsAttributes{
    string group;
    string category;
    string name;
    string tag; 
    string minter; // the name of the minter (who paid the gas fee)
    address soulbound; // wallet address of minter
    address creator; // wallet address of the photo original creator
    uint16 width;
    uint16 height;    
    bytes metadata; // group/category specific metadata
    string description;
}

contract ContentsToken is IERC721, Ownable, ERC721Checkpointable {

    event ContentsCreated(uint256 indexed tokenId, string contents);

    event ContentsBurned(uint256 indexed tokenId);

    event ContentsBought(uint256 indexed tokenId, address newOwner);
    
    event MintTimeUpdated(uint256 mintTime);

    using Strings for uint256;

    // contents committee address.
    address public committee;

    // The tokenId to contentsId
    mapping(uint256 => string) internal tokenContents;
    function getContents(uint256 tokenId) external view returns(string memory){
        require(_exists(tokenId), 'ContentsToken: nonexistent token');
        return tokenContents[tokenId];
    }

    // The contentsId to tokenId
    mapping(string => uint256) internal contentsTokens;
    function getTokenId(string calldata contentsId) external view returns(uint256){
        require(contentsTokens[contentsId] != 0, "contents id should exist ");
        uint256 tokenId = contentsTokens[contentsId];
        require(_exists(tokenId), 'ContentsToken: nonexistent token');
        return tokenId;
    }

    // The tokenId to Attribute
    mapping(uint256 => ContentsAttributes) internal tokenAttributes;
    function getAttributes(uint256 tokenId) external view returns(ContentsAttributes memory){
        require(_exists(tokenId), 'ContentsToken: nonexistent token');
        return tokenAttributes[tokenId];
    }

    // The contents store site
    string public web2Url;

    // The internal contents ID tracker
    uint256 private _currentContentsId = 1;

    // The token mintTimes
    mapping(uint256 => uint256) internal mintTimes;
    
    // Seed data to calculate price
    struct PriceSeed {
        uint256 maxPrice;
        uint256 minPrice;
        uint256 priceDelta;
        uint256 timeDelta;
        uint256 expirationTime;
    }

    // price seed
    PriceSeed public priceSeed;

    // Upgradable admin (only by owner)
    address public admin;
    modifier onlyAdmin() {
        require(owner() == _msgSender() || admin == _msgSender(), "ContentsToken: caller is not the admin");
        _;
    }    
    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }  
    // Mapping from token ID to price
    mapping(uint256 => uint256) private prices;

    // Mapping from contractID to bool
    mapping(address => bool) private authorityContracts;

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    constructor(
        address _committee,
        PriceSeed memory _priceSeed,
        IProxyRegistry _proxyRegistry
    ) ERC721('NounsMapContents', 'NMC') {
        admin = owner();
        committee = _committee;
        proxyRegistry = _proxyRegistry;

        priceSeed.maxPrice = _priceSeed.maxPrice;
        priceSeed.minPrice = _priceSeed.minPrice;
        priceSeed.priceDelta = _priceSeed.priceDelta;
        priceSeed.timeDelta = _priceSeed.timeDelta;
        priceSeed.expirationTime = _priceSeed.expirationTime;

    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override(IERC721, ERC721) returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @notice mint from authority token owner to someone with contents,
     * @dev Call _mintTo with the to address(es).
     */

    function mint(address to, address authority, string calldata contents, ContentsAttributes calldata attr) public returns(uint256) {
        console.log(authority);
        require(authorityContracts[authority],"wrong authority specified ");
        require(contentsTokens[contents] == 0,"already contents exist");
        require(attr.soulbound == msg.sender,"attr.soulbound should be minter");
        require(attr.creator == to,"attr.creator should be same as to address");
        AuthorityTokenInterface authorityContract = AuthorityTokenInterface(authority);
        uint96 vote = authorityContract.getCurrentVotes(msg.sender);
        console.log(msg.sender);
        console.log(vote);
        require(0 < vote, "minter should have authority token");
        console.log(to);
        console.log(contents);
        uint256 id = _currentContentsId++;
        tokenContents[id] = contents;
        contentsTokens[contents] = id;
        tokenAttributes[id] = attr;
        _mint(msg.sender, to, id);
        setMintTime(id);
        emit ContentsCreated(id,contents);
        return id;
    }
         

    /*
     * @notice
     * Buy contents and mint new contents.
     * @dev Call _mintTo with the to address(es).
     */
    function buy(uint256 tokenId) external payable returns (bool) {
        address from = ownerOf(tokenId);
        address to = msg.sender;
        uint256 currentPrice = price(tokenId);
        require(from == address(this), 'Owner is not the contract');
        require(msg.value >= currentPrice, 'Must send at least currentPrice');

        prices[tokenId] = msg.value;
        buyTransfer(to, tokenId);
        
        emit ContentsBought(tokenId, to);
        return true;
    }
    /*
     * @notice get next tokenId.
     */
    function getCurrentToken() external view returns (uint256) {                  
        return _currentContentsId;
    }
    /*
     * @notice set previous mint time.
     */
    function setMintTime(uint256 tokenId) private {
        require(_exists(tokenId), 'ContentsToken: nonexistent token');
        mintTimes[tokenId] = block.timestamp;
        emit MintTimeUpdated(mintTimes[tokenId]);
    }
    /*
     * @notice get previous mint time.
     */
    function getMintTime(uint256 tokenId) external view returns (uint256) {                  
        require(_exists(tokenId), 'ContentsToken: nonexistent token');
        return mintTimes[tokenId];
    }
    /*
     * @notice maxPrice - (time diff / time step) * price step
     */
    function price(uint256 tokenId) private view returns (uint256) {
        uint256 timeDiff = block.timestamp - mintTimes[tokenId];
        if (timeDiff < priceSeed.timeDelta ) {
            return priceSeed.maxPrice;
        }
        uint256 priceDiff = uint256(timeDiff / priceSeed.timeDelta) * priceSeed.priceDelta;
        if (priceDiff >= priceSeed.maxPrice - priceSeed.minPrice) {
            return priceSeed.minPrice;
        }
        return priceSeed.maxPrice - priceDiff;
    }

    /**
     * @notice Burn a contents.
     */
    function burn(uint256 contentsId) public onlyAdmin {
        require(_exists(contentsId), 'ContentsToken: nonexistent token');
        _burn(contentsId);
        emit ContentsBurned(contentsId);
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ContentsToken: URI query for nonexistent token');
        return dataURI(tokenId);
    }

    /**
     * @notice Similar to `tokenURI`, but always serves a base64 encoded data URI
     * with the JSON contents directly inlined.
     */
    function dataURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), 'ContentsToken: URI query for nonexistent token');
        ContentsAttributes memory attr = tokenAttributes[tokenId];
        string memory name = string(abi.encodePacked(attr.name));
        string memory description = string(abi.encodePacked(attr.description));
        string memory url = string(abi.encodePacked(web2Url,tokenContents[tokenId]));
        return  string(abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(
                bytes(
                    abi.encodePacked('{"name":"', name, '", "description":"', description, '", "image": "', url, '"}')
                )
            )
        ));
    }

    /**
     * @notice Set the contentss fes committee.
     * @dev Only callable by the admin.
     */
    function setCommittee(address _committee) external onlyAdmin {
        committee = _committee;
    }

    /**
     * @notice Set the contentss fes committee.
     * @dev Only callable by the admin.
     */
    function setWeb2(string calldata _url) external onlyAdmin {
        web2Url = _url;
    }    

    /**
     * @notice Set the contentss fes committee.
     * @dev Only callable by the admin.
     */
    function addAuthority(address _authority) external onlyAdmin {
        authorityContracts[_authority] = true;
    }

    /**
     * @notice Transfer eth to committee.
     * @dev Only callable by the admin.
     */
    function transfer() external onlyAdmin {
        address payable payableTo = payable(committee);
        payableTo.transfer(address(this).balance);
    }

    /**
     * @notice Set Price Data.
     * @dev Only callable by the admin.
     */
    function setPriceData(PriceSeed memory _priceSeed) external onlyAdmin {
        require(_priceSeed.maxPrice > _priceSeed.minPrice, 'Max price must be larger than Min Price');
        priceSeed.maxPrice = _priceSeed.maxPrice;
        priceSeed.minPrice = _priceSeed.minPrice;
        priceSeed.priceDelta = _priceSeed.priceDelta;
        priceSeed.timeDelta = _priceSeed.timeDelta;
        priceSeed.expirationTime = _priceSeed.expirationTime;
    }

    /**
     * @notice Get Price Data. 
     */
    function getPriceData() public view returns (PriceSeed memory) {
        return priceSeed;
    }
    /**
     * @notice Get the price of token.
     */
    function tokenPrice(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), 'ContentsToken: nonexistent token');
        return prices[tokenId];
    }
    

}
