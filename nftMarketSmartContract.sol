//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
/*
    1.le contrat héritera des contrats OpenZeppelin ERC721Enumerable et Ownable. Le premier a une
     implémentation par défaut de la norme ERC721 (NFT) en plus de quelques fonctions d'assistance
     qui sont utiles lorsqu'il s'agit de collections NFT. Ownable nous permet d'ajouter des privilèges 
     administratifs à certains aspects de notre contrat.
    2.Bibliotheque SafeMathet OpenZeppelin Counters pour traiterl 'arithmétique entière non signée 
    (en empêchant les débordements) et les ID de jeton, respectivement.
*/
contract NFTCollectible is ERC721Enumerable, Ownable {
    //Ici, nous stockons toutes les images téléchargées dans un tableau
    Image[] private images;
    // nous mappons l'adresse des auteurs à leurs images téléchargées
    mapping(address => Image[]) private authorToImages;
    //Ici un struct est utilisé, c'est comme un objet
    //imageUrl contirndral'URL vers IPFS vers un objet JSON contenant l'URL vers l'image
  struct Image {
    uint _id ;
    string name ;
    string description ;
    string[] category ;
    string imageUrl ;
    uint sold_price ;
    uint regular_price ;
    string author;
  }
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    //Le nombre maximum de NFTs qui peuvent être frappés dans votre collection
    uint public constant MAX_SUPPLY = 100;
    // La quantité d'éther nécessaire pour acheter 1 NFT.
    uint public constant PRICE = 0.01 ether;
    //La limite supérieure de NFTs qu'on peut frapper en une seule fois.
    uint public constant MAX_PER_MINT = 10;
    //L'URL IPFS du dossier contenant les métadonnées JSON.
    string public baseTokenURI;

    constructor(string memory baseURI) ERC721("NFT Collection", "NFTC") {
        setBaseURI(baseURI);
    }
     
    //emagasiner les nfts
    /*
    function store( uint memory id, string memory name, string memory desc, string[] memory cat
    , string memory imageUrl, uint memory s1, uint memory s2, string memory author) public {
    Image memory image = Image(id,name,desc,cat,imageUrl,s1,s2,author);

    images.push(image);
    authorToImages[msg.sender].push(image);
  }
  */

  //recuperer tous les nfts
  function retrieveAllImages() public view returns (Image[] memory) {
    return images;
  }
  //recuoerer les nfts par utilisateurs
   function retrieveImagesByAuthor() public view returns (Image[] memory) {
    return authorToImages[msg.sender];
  }

    //fonction nous permettant de reserver certains nft qui ne sont pas à vendre, ici 10
    function reserveNFTs() public onlyOwner {
     uint totalMinted = _tokenIds.current();
     require(
        totalMinted.add(10) < MAX_SUPPLY, "pas assez pour reserver 10 "
     );
     for (uint i = 0; i < 10; i++) {
          _mintSingleNFT();
     }
    }
    /*
        Nos métadonnées JSON NFT sont disponibles à cette URL IPFS : 
        ipfs://QmZbWNKJPAjxXuNFSEaksCJVd1M6DaKQViJBYPK2BdpDEP/
    */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    //permet de changer de lien au cas ou l'utilisateur le souhaite apres deployement
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }
    /*
        1.Nos utilisateurs et clients appelleront cette fonction lorsqu'ils voudront acheter et frapper 
         des NFTs de notre collection et Comme ils envoient de l'éther à cette fonction, nous devons 
         la marquer comme payable.
        2.Nous devons effectuer trois vérifications avant d'autoriser quoi que ce soit :
            a.Il reste suffisamment de NFT dans la collection pour que l'appelant puisse creer 
            b.L'appelant a demandé à frapper moins que le nombre maximum de NFTs autorisés par transaction.
            c.L'appelant a envoyé suffisamment d'ETH pour frapper le nombre de NFT demandé.
    */
    function mintNFTs(uint _count) public payable {
        uint totalMinted = _tokenIds.current();

        require(totalMinted.add(_count) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(_count >0 && _count <= MAX_PER_MINT, "Cannot mint specified number of NFTs.");
        require(msg.value >= PRICE.mul(_count), "Not enough ether to purchase NFTs.");
        //si les validations sont verifiees 
        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }
    //la fonction qui est appelée chaque fois que nous (ou un tiers) voulons frapper un NFT.
    function _mintSingleNFT() private {
        uint newTokenID = _tokenIds.current();
        //
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }

    /*
        une fonction qui renvoie tous les identifiants appartenant à un détenteur particulier. Ceci est 
        rendu super simple par les fonctions balanceOf et tokenOfOwnerByIndex. Le premier nous indique 
        combien de jetons un propriétaire particulier détient, et le second peut être utilisé pour obtenir 
        tous les identifiants qu'un propriétaire possède, c-à-d tous les nft qu'il detient
    */
    function tokensOfOwner(address _owner) external view returns (uint[] memory) {

        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    /*
        fonction qui nous permet de retirer tout le solde ether du contrat, marqué comme onlyOwner car seul
        le user pourra faire appelle à cette fonction
    */
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

}