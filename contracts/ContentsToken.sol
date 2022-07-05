// SPDX-License-Identifier: GPL-3.0

/// @title The NounsMap contents ERC-721 token

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

contract ContentsToken is IERC721, Ownable, ERC721Checkpointable {

    event ContentsCreated(uint256 indexed tokenId);

    event ContentsBurned(uint256 indexed tokenId);

    event ContentsBought(uint256 indexed tokenId, address newOwner);
    
    event MintTimeUpdated(uint256 mintTime);

    using Strings for uint256;

    // contents committee address.
    address public committee;
    
    // The contents contents
    mapping(uint256 => string) internal tokenContents;

    // The contents store site
    string public web2Url;


    // The internal contents ID tracker
    uint256 private _currentContentsId;

    // The previous mint time
    uint256 public mintTime;
    
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

    // developer address.
    address public developer;
    
    // Mapping from token ID to price
    mapping(uint256 => uint256) private prices;

    // Mapping from contractID to bool
    mapping(address => bool) private authorityContracts;

    
    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    constructor(
        address _developer,
        address _committee,
        PriceSeed memory _priceSeed,
        IProxyRegistry _proxyRegistry
    ) ERC721('NounsMapContents', 'NMC') {
        developer = _developer;
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

    function mint(address to, address authority, string calldata contents) public returns(uint256) {
        console.log(authority);
        require(authorityContracts[authority],"wrong authority specified ");
        AuthorityTokenInterface authorityContract = AuthorityTokenInterface(authority);
        uint96 vote = authorityContract.getCurrentVotes(msg.sender);
        console.log(msg.sender);
        console.log(vote);
        require(0 < vote, "minter should have authority token");
        console.log(to);
        console.log(contents);
        uint256 id = _currentContentsId++;
        tokenContents[id] = contents;
        _mint(msg.sender, to, id);
        setMintTime();
        emit ContentsCreated(id);
        return id;
    }
         

    /*
     * @notice
     * Buy contents and mint new contents.
     * @dev Call _mintTo with the to address(es).
     */
    function buy(uint256 tokenId) external payable returns (uint256) {
        address from = ownerOf(tokenId);
        address to = msg.sender;
        uint256 currentPrice = price();
        require(from == address(this), 'Owner is not the contract');
        require(tokenId == (_currentContentsId - 1), 'Not latest Noun');
        require(msg.value >= currentPrice, 'Must send at least currentPrice');

        prices[tokenId] = msg.value;
        buyTransfer(to, tokenId);
        
        emit ContentsBought(tokenId, to);
        return _mintNext(address(this));
    }
    /*
     * @notice set previous mint time.
     */
    function setMintTime() private {
        mintTime = block.timestamp;
        emit MintTimeUpdated(mintTime);
    }
    /*
     * @notice get next tokenId.
     */
    function getCurrentToken() external view returns (uint256) {                  
        return _currentContentsId;
    }
    /*
     * @notice get previous mint time.
     */
    function getMintTime() external view returns (uint256) {                  
        return mintTime;
    }
    /*
     * @notice maxPrice - (time diff / time step) * price step
     */
    function price() private view returns (uint256) {
        uint256 timeDiff = block.timestamp - mintTime;
        if (timeDiff < priceSeed.timeDelta ) {
            return priceSeed.maxPrice;
        }
        uint256 priceDiff = uint256(timeDiff / priceSeed.timeDelta) * priceSeed.priceDelta;
        if (priceDiff >= priceSeed.maxPrice - priceSeed.minPrice) {
            return priceSeed.minPrice;
        }
        return priceSeed.maxPrice - priceDiff;
    }
    /*
     * @notice anyone can burn a contents after expiration time.
     */
    function burnExpiredToken() public {
        uint256 timeDiff = block.timestamp - mintTime;
        if (timeDiff > priceSeed.expirationTime) {
            burn(_currentContentsId - 1);
        }
        _mintNext(address(this));
    }
    
    /**
     * @notice Burn a contents.
     */
    function burn(uint256 contentsId) public onlyOwner {
        require(_exists(contentsId), 'ContentsToken: URI query for nonexistent token');
        if (_currentContentsId - 1 == contentsId) {
            _mintNext(address(this));
        }
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

        string memory contentsId = tokenId.toString();
        string memory name = string(abi.encodePacked('NounsMap ', contentsId));
        string memory description = string(abi.encodePacked('NounsMap ', contentsId, ' is a map with photo and movie.'));
        string memory url = string(abi.encodePacked(web2Url,tokenId.toString()));
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
     * @dev Only callable by the owner.
     */
    function setCommittee(address _committee) external onlyOwner {
        committee = _committee;
    }

    /**
     * @notice Set the contentss fes committee.
     * @dev Only callable by the owner.
     */
    function setWeb2(string calldata _url) external onlyOwner {
        web2Url = _url;
    }    

    /**
     * @notice Set the contentss fes committee.
     * @dev Only callable by the owner.
     */
    function addAuthority(address _authority) external onlyOwner {
        authorityContracts[_authority] = true;
    }

    function _mintNext(address to) internal returns (uint256) {
        if (_currentContentsId % 10 == 0) {
            _mintTo(developer, _currentContentsId++);
        }
        setMintTime();
        return _mintTo(to, _currentContentsId++);
    }
    /**
     * @notice Mint a Noun with `contentsId` to the provided `to` address.
     */
    function _mintTo(address to, uint256 contentsId) internal returns (uint256) {
        _mint(owner(), to, contentsId);
        emit ContentsCreated(contentsId);

        return contentsId;
    }

    /**
     * @notice Transfer eth to committee.
     * @dev Only callable by the Owner.
     */
    function transfer() external onlyOwner {
        address payable payableTo = payable(committee);
        payableTo.transfer(address(this).balance);
    }

    /**
     * @notice Set Price Data.
     * @dev Only callable by the Owner.
     */
    function setPriceData(PriceSeed memory _priceSeed) external onlyOwner {
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
        require(_exists(tokenId), 'ContentsToken: URI query for nonexistent token');
        return prices[tokenId];
    }
    
    /**
     * @notice Set developer.
     * @dev Only callable by the Owner.
     */
    function setDeveloper(address _developer) external onlyOwner {
        developer = _developer;
    }

}
