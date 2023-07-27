 Being able to tokenize assets, such as commodities, securities, derivatives, currencies, and other types of assets, can allow financial institutions like banks and brokerage firms to have easier means of managing, trading, and accounting for different assets, not only for themselves but also for their trade partners.
These organizations can offset databasing costs by having the accounting of their assets on decentralized networks, making them easier to exchange and cheaper to operate. By moving hosting fees to transaction fees, the management of these assets becomes incredibly inexpensive and allows these organizations to focus more on their business model rather than on the hosting and operation of the systems that run their business.
Having assets tokenized on decentralized networks allows for a shared accounting of unique assets that would otherwise be siloed in independent databases operated by individual organizations. The means of syncing information between organizations during an exchange or transfer can be slow and a manual process when dealing with international organizations. When these assets are tokenized and used as shared accounting tools, the means of exchanging ownership of different assets becomes simple.
I built a proof-of-concept smart contract that takes the place of a broker who is not only tokenizing their possessed assets (asset certificates custodied under management) for their clients but also allows for these assets to be exchanged with other brokerage services. This contract is meant to illustrate that utilizing smart contracts and tokenization as a tool can allow for a simple means of management of these new assets, a cheaper operational cost, and a shared accounting tool that allows for engagement with anyone who also operates on the XDC network.
This asset smart contract provides a means for administrators to manage the contract by possessing a particular token called the handlerToken. The handler token is a token that acts as a key and allows the broker to create new assets with predefined sets of attributes.
When the handler deploys the contract the handler key is generated with a random integer not to interfere with the other asset tokens being generated, each token is paired to an integer.
```solidity
 //initializer Execute some initial code as contract is launched
 constructor(string memory _URI) ERC1155(_URI) {
 handlerToken = uint(keccak256(abi.encodePacked(_URI)));
 _mint(msg.sender,handlerToken,1, "");
 }
```
Also, when launching the contract, you must set a Uniform Resource Identifier (URI). The URI is a set of metadata referenced by the user interface (UI) to allow data about the assets to be depicted on a screen. This typically includes attributes about the asset like images, the asset's origin broker, or even a name and description of the asset.
These attributes are typically hosted off-chain, but their links are referenced in the URI.
```json
{
 "name": "{id}",
 "description": "https://hostedSite/description/{id}",
 "image": "https://hostedSite/{id}",
 "Broker": "QTrade" 
}
```
The administrator becomes the initial handlerToken holder as the contract is launched. This special token grants exclusive rights to certain contract functions.
```solidity
//Store Asset details within contract 
 mapping(uint => Tokens) public tokens;
 struct Tokens{
 string name;
 string description;
 string image;
 string assetType;
 }
//This function allows you to add or create new tokens and log their data into the smart contract 
 function AddToken(string memory name, string memory att1, string memory att2 ,string memory att3,string memory assetType)public handler returns(bool){
 _mint(msg.sender,totalCoins,1, "");
 tokens[totalCoins] = Tokens(name,att1,att2,assetType);
 totalCoins++;
 return true;
 }
```
Once the contract is launched, the handler can call the AddToken function to create a new token to represent an asset. These tokens represent unique assets possessed by the broker with predefined attributes. The trust that these assets represent tangible means of ownership relies on the trust of the broker who issued them. Similar to how assets custodied on an app like Robin Hood are trusted due to Robin Hood being a trusted organization, if I were to create a clone of Robin Hood and sell assets that I do not currently possess, the user would not actually be buying the asset, and my sales would be fraudulent.
The firm can provide the token's name and attributes during the token creation process. In practice, these attributes can be anything about the asset that is important, like total supply, origin, expiration date (commodities/derivatives), or any other detail to describe the asset.
```solidity
 //view token name and price of token to gauge what asset is corelated to the index nuber acociatyed with the asset
 function viewToken(uint Token)public view returns(string memory, string memory, string memory,string memory) {
 return (tokens[Token].name, tokens[Token].description, tokens[Token].image, tokens[Token].assetType);
 }
```
Users can view the name of a token and its attributes by calling the viewToken function.
The contract allows the handlerToken holder to move or destroy abandoned tokens to help recover lost or stolen assets.
```solidity
 //if the broker for any reason need to move the asset from an abandond account
 //they can use the move Asset function 
 function moveAsset(uint Token,address _userA,address _userB)public returns(bool){
 require(balanceOf(_userA, Token) >= 1, "Insufficient balance");
 _burn(_userA, Token, 1);
 _mint(_userB,Token,1, "");
 return true;
 }
 function destroyAsset(uint Token,address _userA)public returns(bool){
 require(balanceOf(_userA, Token) >= 1, "Insufficient balance");
 _burn(_userA, Token, 1);
 return true;
 }
```
In summary, this smart contract offers a convenient and secure way for finance firms and brokers to create and manage new assets on XDC. The handlerToken mechanism provides the necessary access control, allowing administrators to govern the contract while empowering brokers to create unique and valuable representations of their assets to be easily exchanged.

These Assets are accounting tools and as tools they are built to allow for a better more productive financial system.

```solidity
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
contract Asset is ERC1155 {
 uint public totalCoins = 0; //toal tokens
 uint public handlerToken; 
 
 //initializer Execute some initial code as contract is launched
 constructor(string memory _URI) ERC1155(_URI) {
 handlerToken = uint(keccak256(abi.encodePacked(_URI)));
 _mint(msg.sender,handlerToken,1, "");
 }
 //The Handler function allows the holder of the handler token to allows the owner of the contract create more assets 
 // As well as allows only the handler to redeem value from the contract
 modifier handler(){
 require(balanceOf(msg.sender,handlerToken) == 1, "user does not hold handlerToken");
 _;
 }
//Store Asset details within contract 
 mapping(uint => Tokens) public tokens;
 struct Tokens{
 string name;
 string description;
 string image;
 string assetType;
 }
//This function allows you to add or create new tokens and log their data into the smart contract 
 function AddToken(string memory name, string memory att1, string memory att2 ,string memory att3,string memory assetType)public handler returns(bool){
 _mint(msg.sender,totalCoins,1, "");
 tokens[totalCoins] = Tokens(name,att1,att2,assetType);
 totalCoins++;
 return true;
 }
//view token name and price of token to gauge what asset is corelated to the index nuber acociatyed with the asset
 function viewToken(uint Token)public view returns(string memory, string memory, string memory,string memory) {
 return (tokens[Token].name, tokens[Token].description, tokens[Token].image, tokens[Token].assetType);
 }
 //if the broker for any reason need to move the asset from an abandond account
 //they can use the move Asset function 
 function moveAsset(uint Token,address _userA,address _userB)public returns(bool){
 require(balanceOf(_userA, Token) >= 1, "Insufficient balance");
 _burn(_userA, Token, 1);
 _mint(_userB,Token,1, "");
 return true;
 }
 function destroyAsset(uint Token,address _userA)public returns(bool){
 require(balanceOf(_userA, Token) >= 1, "Insufficient balance");
 _burn(_userA, Token, 1);
 return true;
 }
}
```
**GitHub: ** https://github.com/CoinClubQuincy/XDC-Automated-Asset-Management