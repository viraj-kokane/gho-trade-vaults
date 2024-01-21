// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './AssetPoolToken.sol';

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface INonStandardERC20 {

     function totalSupply() external view returns (uint256);

     function balanceOf(address owner) external view returns (uint256 balance);

     function transfer(address dst, uint256 amount) external;

     function transferFrom(
         address src,
         address dst,
         uint256 amount
     ) external;

     function approve(address spender, uint256 amount)
         external
         returns (bool success);

     function allowance(address owner, address spender)
         external
         view
         returns (uint256 remaining);

     event Transfer(address indexed from, address indexed to, uint256 amount);
     event Approval(
         address indexed owner,
         address indexed spender,
         uint256 amount
     );
}

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract ERC20Detailed is ERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract TradeVault is ERC20Detailed {

    using SafeMath for uint256;
    
    uint256 public cashDecimals;
    uint256 public assetTokenMultiplier;
    
    ERC20Detailed internal cash;
    AssetPoolToken internal assetPoolToken;
    ERC20Detailed internal assetToken;
    
    uint256 public assetToCashRate;
    uint256 public cashValuationCap;

    address public ghoTokenAddressSepolia = 0xc4bF5CbDaBE595361438F8c6a187bDc330539c60;
    
    event ValuationCapUpdated(uint256 cashCap);
    event OwnerChanged(address indexed newOwner);
    event TradeVaultPoolRateUpdated(uint256 tradeVaultPoolRate);
    event AssetPoolRateUpdated(uint256 assetPoolrate);
    event CashTokensRedeemed(address indexed user,uint256 redeeemedCashAmount,uint256 outputAssetAmount,uint256 mintedTradeVaultPoolAmount);
    event TradeVaultPoolTokensBurnt(address indexed user,uint256 burntTradeVaultPoolAmount,uint256 outputAssetAmount,uint256 outputCashAmount);
    event AssetTokensRedeemed(address indexed user,uint256 redeemedAssetToken,uint256 outputCashAmount,uint256 mintedAssetPoolAmount);
    event AssetPoolTokensBurnt(address indexed user,uint256 burntAssetPoolToken,uint256 outputAssetAmount,uint256 outputCashAmount);
    event FallbackCalled(address sender, uint256 amount);
    event Received(address sender, uint256 amount);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    fallback() external payable {
        emit FallbackCalled(msg.sender, msg.value);
    }
    
    address payable public owner;
    
    modifier onlyOwner() {
        require (msg.sender == owner,"Account not Owner");
        _;
    }
        
    constructor (address assetTokenAddress,uint256 _assetToCashRate,uint256 cashCap,string memory name,string memory symbol) 
    ERC20Detailed(name, symbol, 18)  
    {
        require(msg.sender != address(0), "Zero address cannot be owner/contract deployer");
        owner = payable(msg.sender);
        require(assetTokenAddress != address(0), "assetToken is the zero address");
        require(_assetToCashRate != 0, "Asset to cash rate can't be zero");
        cash = ERC20Detailed(ghoTokenAddressSepolia);
        assetToken = ERC20Detailed(assetTokenAddress);
        cashDecimals = cash.decimals();
        assetTokenMultiplier = (10**uint256(assetToken.decimals()));
        assetToCashRate = ((10**(cashDecimals)).mul(_assetToCashRate)).div(1e18);
        updateCashValuationCap(cashCap);
        assetPoolToken = new AssetPoolToken();
    }
    
    function updateCashValuationCap(uint256 cashCap) public onlyOwner returns(uint256){
        cashValuationCap=cashCap;
        emit ValuationCapUpdated(cashCap);
        return cashValuationCap;
    }
    
    function changeOwner(address payable newOwner) external onlyOwner {
        owner=newOwner;
        emit OwnerChanged(newOwner);
    }
    
    function assetPoolTokenAddress() public view returns (address) {
        return address(assetPoolToken);
    }
    
    function _preValidateData(address beneficiary, uint256 amount) internal pure {
        require(beneficiary != address(0), "Beneficiary can't be zero address");
        require(amount != 0, "amount can't be 0");
    }
    
    function contractCashBalance() public view returns(uint256 cashBalance){
        return cash.balanceOf(address(this));
    } 
    
    function contractAssetTokenBalance() public view returns(uint256 assetTokenBalance){
        return assetToken.balanceOf(address(this));
    }
    
    function assetTokenCashValuation() internal view returns(uint256){
        uint256 cashEquivalent=(contractAssetTokenBalance().mul(assetToCashRate)).div(assetTokenMultiplier);
        return cashEquivalent;
    }
    
    function contractCashValuation() public view returns(uint256 cashValauation){
        uint256 cashEquivalent=(contractAssetTokenBalance().mul(assetToCashRate)).div(assetTokenMultiplier);
        return contractCashBalance().add(cashEquivalent);
    }

    function depositCash(uint256 inputCashAmount) external {    
        if(cashValuationCap!=0)
        {
            require(inputCashAmount.add(contractCashValuation())<=cashValuationCap,"inputCashAmount exceeds cashValuationCap");
        }
        address sender= msg.sender;
        _preValidateData(sender,inputCashAmount);

        uint256 actualCashReceived = doTransferIn(
            address(cash),
            sender,
            inputCashAmount
        );
        
        uint256 outputAssetAmount = 0;
        uint256 tradeVaultPoolTokens = 0;
        
        uint256 assetToRedeem=(actualCashReceived.mul(assetTokenMultiplier)).div(assetToCashRate);
        
        if(assetToRedeem <= contractAssetTokenBalance()){
            outputAssetAmount = assetToRedeem;
            if(outputAssetAmount > 0){
                doTransferOut(address(assetToken), sender, outputAssetAmount);
            }
        }
        
        else{
            outputAssetAmount=contractAssetTokenBalance();
            if(outputAssetAmount > 0){
                doTransferOut(address(assetToken), sender, outputAssetAmount);
            }
            uint256 remainingAsCashTokens = ((assetToRedeem.sub(outputAssetAmount)).mul(assetToCashRate)).div(assetTokenMultiplier);
            
            // calculate TradeVaultPool token amount to be minted
            tradeVaultPoolTokens = remainingAsCashTokens;
            _mint(sender, tradeVaultPoolTokens); //Minting  TradeVaultPool Token
        }
        emit CashTokensRedeemed(sender,actualCashReceived,outputAssetAmount,tradeVaultPoolTokens);
    }
    
    function burnTradeVaultPoolToken(uint256 tradeVaultPoolTokenAmount) external {  
        address sender= msg.sender;
        _preValidateData(sender,tradeVaultPoolTokenAmount);
        
        uint256 assetToRedeem = tradeVaultPoolTokenAmount.mul(assetTokenMultiplier).div(assetToCashRate);
        _burn(sender, tradeVaultPoolTokenAmount);
        
        uint256 outputAssetToken = 0;
        uint256 outputCashAmount = 0;
        if( assetToRedeem<= contractAssetTokenBalance() )
        {
            outputAssetToken=assetToRedeem;//calculate Asset token amount to be return
            if(outputAssetToken > 0){
                doTransferOut(address(assetToken), sender, outputAssetToken);
            }
        }
        
        else
        {
            outputAssetToken=contractAssetTokenBalance();
            if(outputAssetToken > 0){
                doTransferOut(address(assetToken), sender, outputAssetToken);
            }
            outputCashAmount=tradeVaultPoolTokenAmount.sub(outputAssetToken);// calculate cash amount to be return
            doTransferOut(address(cash), sender, outputCashAmount);
        }
         
        emit TradeVaultPoolTokensBurnt(sender,tradeVaultPoolTokenAmount,outputAssetToken,outputCashAmount);
    }
    
    function depositAsset(uint256 inputAssetTokenAmount) external {    
        address sender= msg.sender;
        _preValidateData(sender,inputAssetTokenAmount);

        uint256 actualAssetReceived = doTransferIn(
            address(assetToken),
            sender,
            inputAssetTokenAmount
        );
        uint256 outputCashAmount = 0;
        uint256 mintableAssetPoolTokens = 0;
        
        uint256 cashToRedeem=(actualAssetReceived.mul(assetToCashRate)).div(assetTokenMultiplier);
        
        if(cashToRedeem <= contractCashBalance()){
            outputCashAmount = cashToRedeem;
            if(outputCashAmount > 0){
                doTransferOut(address(cash), sender, outputCashAmount);
            }
        }
        else{
            outputCashAmount=contractCashBalance();
            if(outputCashAmount > 0){
                doTransferOut(address(cash), sender, outputCashAmount);
            }
            uint256 remainingAsAssetTokens=((cashToRedeem.sub(outputCashAmount)).mul(assetTokenMultiplier)).div(assetToCashRate);
            
            // calculate Asset Pool token amount to be minted
            mintableAssetPoolTokens = remainingAsAssetTokens;
            assetPoolToken.mint(sender, mintableAssetPoolTokens); //Minting  Asset Pool Token
        }
        emit AssetTokensRedeemed(sender,actualAssetReceived,outputCashAmount,mintableAssetPoolTokens);
    }
    
    function burnAssetPoolToken(uint256 assetPoolTokenAmount) external {  
        address sender= msg.sender;
        _preValidateData(sender,assetPoolTokenAmount);
        uint256 cashToRedeem = (assetPoolTokenAmount.mul(assetToCashRate)).div(assetTokenMultiplier);
        assetPoolToken.burnFrom(sender,assetPoolTokenAmount);
        
        uint256 outputAssetToken = 0;
        uint256 outputCashAmount = 0;
        if( cashToRedeem<=contractCashBalance()  )
        { 
            outputCashAmount = cashToRedeem;
            if(outputCashAmount > 0){
                doTransferOut(address(cash), sender, outputCashAmount);
            }
            
        }
        else
        {
            outputCashAmount=contractCashBalance();
            if(outputCashAmount > 0){
                doTransferOut(address(cash), sender, outputCashAmount);
            }
            uint256 remainingCash = cashToRedeem.sub(outputCashAmount);
            outputAssetToken=(remainingCash.mul(assetTokenMultiplier)).div(assetToCashRate);
            doTransferOut(address(assetToken), sender, outputAssetToken);
        }
        emit AssetPoolTokensBurnt(sender,assetPoolTokenAmount,outputAssetToken,outputCashAmount);
    }
    
    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferIn(
        address tokenAddress,
        address from,
        uint256 amount
    ) internal returns (uint256) {
        INonStandardERC20 token = INonStandardERC20(tokenAddress);
        uint256 balanceBefore = IERC20(tokenAddress).balanceOf(address(this));
        token.transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := not(0) // set success to true
                }
                case 32 {
                    // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0) // Set `success = returndata` of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(tokenAddress).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }
    
    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferOut(
        address tokenAddress,
        address to,
        uint256 amount
    ) internal {
        INonStandardERC20 token = INonStandardERC20(tokenAddress);
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := not(0) // set success to true
                }
                case 32 {
                    // This is a complaint ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0) // Set `success = returndata` of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }
}