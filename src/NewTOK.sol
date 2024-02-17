// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

error NotOrderOwner();
error InsufficientBalanceToRefund();
error OrderDoesNotExist();
error InsufficientBalanceForTransaction();
error insufficientEquityToken();
error WrongEquityToken();
error ExceedsOrderAmount();
error NotTokenOwner();
error InsufficientEquityTokenAmount();
error ContractIsTokenOwner();
error InvalidTokenAddress();
error InvalidOperation();

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "solady/tokens/ERC20.sol";
import "solady/auth/Ownable.sol";

contract TOK is Ownable{
    IERC20 private coinToken;

    mapping(uint256 => address) public orderToOwner;
    mapping(address => uint256) public stableCoinBalance;
    mapping(uint256 => uint256) public orderPrices;
    mapping(uint256 => uint256) public orderTokenAmounts;
    mapping(uint256 => address) public orderTokenAddresses;
    mapping(address => uint256) public equityTokenOwnershipAmount;

    // Events for monitoring contract interactions
    event OrderCreated(uint256 indexed orderId, address tokenAddress, uint256 tokenAmount, uint256 price);
    event OrderCancelled(uint256 indexed orderId);
    event EquityTokenDeposited(uint256 indexed orderId, uint256 amount);
    event TransactionExecuted(uint256 indexed orderId, address newOwner, uint256 amount);
    event OrderModified(uint256 indexed orderId);
    event OrderUpdated(uint256 indexed orderId, address indexed tokenAddress, uint256 tokenAmount, uint256 price);

    constructor(IERC20 _coinToken) {
        coinToken = _coinToken;
    }

   //address _tokenAddress to musi być nasza akcjatoken???????? TAK
     function createOrder(uint256 _price, address _tokenAddress, uint256 _tokenAmount) external  {
        // Generate a unique orderId based on inputs and timestamp
        uint256 orderId = uint256(keccak256(abi.encodePacked(_tokenAddress, _tokenAmount, _price, msg.sender, block.timestamp)));
        uint256 totalOrderAmount = _price * _tokenAmount;
        
        //ASSEMBLY transferujesz stable oplate robisz za stworzenie ordera
             assembly{

            let tok := sload(coinToken.slot)

            mstore(0x00, hex"23b872dd")
            mstore(0x04, caller())
            mstore(0x24, address())
            mstore(0x44, totalOrderAmount)
            
           //hardcodowanie tokenu stablecoina CZY LEPIEJ TAK?
            if iszero(call(gas(), tok, 0, 0x00, 0x64, 0, 0)) {
                revert(0, 0)
            }
            
        }
        // Update mappings with order details ASSEMBLY IN MIND
        orderToOwner[orderId] = msg.sender;
        stableCoinBalance[msg.sender] += totalOrderAmount;
        orderPrices[orderId] = _price;
        orderTokenAmounts[orderId] = _tokenAmount;
        //tu sie zapisuje mapping tych tokenow akcjatoken
        orderTokenAddresses[orderId] = _tokenAddress;


        emit OrderCreated(orderId, msg.sender, _tokenAmount, _price);
    }


//cancel order by owner
   function cancelOrder(uint256 _orderId) external {
    if (orderToOwner[_orderId] != msg.sender) revert NotOrderOwner();
    uint256 refundAmount = orderPrices[_orderId] * orderTokenAmounts[_orderId];
    if (stableCoinBalance[msg.sender] < refundAmount) revert InsufficientBalanceToRefund();
    //mapping update
    stableCoinBalance[msg.sender] -= refundAmount;

    assembly{

            let tok := sload(coinToken.slot)
            mstore(0x00, hex"23b872dd")
            mstore(0x04, address())
            mstore(0x24, caller())
            mstore(0x44, refundAmount)
            
           //hardcodowanie tokenu stablecoina CZY LEPIEJ TAK?
            if iszero(call(gas(), tok, 0, 0x00, 0x64, 0, 0)) {
                revert(0, 0)
            }
    
        }

    // Clean up order mappings
    delete orderToOwner[_orderId];
    delete orderPrices[_orderId];
    delete orderTokenAmounts[_orderId];
    delete orderTokenAddresses[_orderId];

    emit OrderCancelled(_orderId);
   }


    

    // Deposit equity tokens to an existing order no to te musze podać w argumentach przecie adres tego akcjatoken
      
         function depositEquityTokens(uint256 _orderId, uint256 _amount, address _AkcjaToken) external {
            //sprawdzać czy adress _akcjatoken jest w mappingu i jest tym adressem pasującym do zioma orderTokenAddresses;
        if (orderTokenAddresses[_orderId] != _AkcjaToken) revert WrongEquityToken();
        if (orderToOwner[_orderId] == address(0)) revert OrderDoesNotExist();
        if (orderToOwner[_orderId] != msg.sender) revert NotOrderOwner();

      // Ensure deposit amount does not exceed the total order token amount
        if (_amount > orderTokenAmounts[_orderId]) revert ExceedsOrderAmount();

        assembly{
 
            mstore(0x00, hex"23b872dd")
            mstore(0x04, caller())
            mstore(0x24, address())
            mstore(0x44, _amount)
            
           //hardcodowanie tokenu stablecoina CZY LEPIEJ TAK?
            if iszero(call(gas(), _AkcjaToken, 0, 0x00, 0x64, 0, 0)) {
                revert(0, 0)
            }
        }

        equityTokenOwnershipAmount[msg.sender] += _amount;
        emit EquityTokenDeposited(_orderId, _amount);
         
         }

//cancel orderbytokenowner
//musimy wpisywać te akcjatoken w argumentach bo to są rózne adresy tych equity tokenów ze wzgledu na te factory
    function cancelOrderByTokenOwner(uint256 _orderId, address _AkcjaToken) external {
      
    if (orderToOwner[_orderId] != msg.sender) revert NotTokenOwner();
    if (orderTokenAddresses[_orderId] != _AkcjaToken) revert WrongEquityToken();
    if (equityTokenOwnershipAmount[msg.sender] < orderTokenAmounts[_orderId]) revert InsufficientEquityTokenAmount();
   // if (_AkcjaToken == address(this)) revert ContractIsTokenOwner();   
       equityTokenOwnershipAmount[msg.sender] -= orderTokenAmounts[_orderId];
        uint256 _amount = orderTokenAmounts[_orderId];
          assembly{
            mstore(0x00, hex"23b872dd")
            mstore(0x04, caller())
            mstore(0x24, address())
            mstore(0x44, _amount)
    
            if iszero(call(gas(), _AkcjaToken, 0, 0x00, 0x64, 0, 0)) {
                revert(0, 0)
            }
            
        }

        // Clean up the order mappings
        delete orderToOwner[_orderId];
        delete orderPrices[_orderId];
        delete orderTokenAmounts[_orderId];
        delete orderTokenAddresses[_orderId];

     
    }


 // onlyValidState(_orderId, State.Created) w ogóle czy potrzebujemy tego state created?!?!?!?!?!
//  orders[_orderId].currentState = State.OrderOwnerChanged;
    function changeOrderByOwner(uint256 _orderId, address _tokenAddress) external {
        if (orderToOwner[_orderId] == address(0)) revert OrderDoesNotExist();
        if (orderToOwner[_orderId] != msg.sender) revert NotOrderOwner();
        if (_tokenAddress == address(0)) revert InvalidTokenAddress();

        orderTokenAddresses[_orderId] = _tokenAddress;

    // czange price jest i token amount? czy nie robić tego? bo w oryginale niby nie daja mozliwosci ale emity są takie jakie są
        emit OrderUpdated(_orderId, _tokenAddress, orderTokenAmounts[_orderId], orderPrices[_orderId]);
    }


         function ModifyOrderByPpra(uint256 _orderId, uint256 mode, uint256 newValue) external onlyOwner {
        if (orderToOwner[_orderId] == address(0)) revert OrderDoesNotExist();

        if (mode == 1) { // Adjust price
            orderPrices[_orderId] = newValue;
        } else if (mode == 2) { // Adjust amount
            orderTokenAmounts[_orderId] = newValue;
        }
        emit OrderModified(_orderId);
    }

// na kij te eimity

// BRAKUJĄCE FUNKCJE DALEJ DO NAPISANIA JAK FUNKCJA TRANSACT


}
