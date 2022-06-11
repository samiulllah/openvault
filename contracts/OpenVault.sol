// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract OpenVault is ERC20,Ownable{
    using SafeMath for uint;
    uint256 public tokensPerEth = 1;
    address developmentWallet;


    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event Taxation(uint256 burntAmount,uint256 taxAmount);
    constructor() ERC20("OpenVault", "OVT") {
        _mint(address(this), 1000000000*10**18); // mint 1 billion tokens to contract address
    }

    // buy tokens
    function buyTokens() public payable returns (uint256 tokenAmount) {
        require(msg.value > 0, "Send ETH to buy some tokens");
    
        uint256 amountToBuy = msg.value * tokensPerEth;

        // check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 contractBalance = balanceOf(address(this));
        require(contractBalance >= amountToBuy, "Contract has not enough tokens in its balance");
        // let put tax
        uint256 taxFee=amountToBuy.mul(3).div(100); // 3% buy fee
        //Transfer token to the msg.sender
        (bool sent) = transfer(msg.sender, amountToBuy);
        require(sent, "Failed to transfer token to user");
        _distributeTax(taxFee,true);
        emit BuyTokens(msg.sender, msg.value, amountToBuy);
        return amountToBuy;
   }

   // sell tokens
  function sellTokens(uint256 tokenAmountToSell) public {
        // Check that the requested amount of tokens to sell is more than 0
        require(tokenAmountToSell > 0, "Specify an amount of token greater than zero");

        // Check that the user's token balance is enough to do the swap
        uint256 userBalance =balanceOf(msg.sender);
        require(userBalance >= tokenAmountToSell, "Your balance is lower than the amount of tokens you want to sell");

       // let put tax
        uint256 taxFee=tokenAmountToSell.mul(5).div(100); // 3% buy fee
        tokenAmountToSell=tokenAmountToSell.sub(taxFee);

       // Check that the contract balance is enough to do the swap
        uint256 amountOfETHToTransfer = tokenAmountToSell / tokensPerEth;
        uint256 ownerETHBalance = address(this).balance;
        require(ownerETHBalance >= amountOfETHToTransfer, "Contract has not enough funds to accept the sell request");
        // transfer
        _transferToContractSell(tokenAmountToSell);
        // tax
        _distributeTax(taxFee,false);
        // eth transfer
        bool sent=false;
        (sent,) = msg.sender.call{value: amountOfETHToTransfer}("");
        require(sent, "Failed to send ETH to the user");
   }
   function _distributeTax(uint256 taxAmount,bool isBuying)internal{
      uint256 burnAmount=taxAmount.mul(40).div(100);
      uint256 devAmount=taxAmount.mul(60).div(100);
      _burn(msg.sender,burnAmount);
      if(!isBuying){
        _transferToContractSell(devAmount);
      }else{
        _transfer(msg.sender,address(this), devAmount);
      }
      emit Taxation(burnAmount,devAmount);
   }
   
   function _transferToContractSell(uint256 amount)internal{
      (bool sent) = transferFrom(msg.sender, address(this), amount);
      require(sent, "Failed to transfer tokens from user to vendor");
   }
 
   // withdraw eth
   function withdraw() public onlyOwner {
    uint256 ownerBalance = address(this).balance;
    require(ownerBalance > 0, "Owner has not balance to withdraw");

    (bool sent,) = msg.sender.call{value: address(this).balance}("");
    require(sent, "Failed to send user balance back to the owner");
  }
}