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
error NotAuthorizedToCancelOrder();

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "solady/tokens/ERC20.sol";
import "solady/auth/Ownable.sol";
import "./IAkcjaToken.sol";

contract TOK is Ownable {
    IERC20 private coinToken;
    address private bank;

    struct Order {
        address orderOwner;
        address tokenAddress;
        uint256 tokenAmount;
        uint256 pricePerToken;
        bool ppraFee;
    }

    mapping(uint256 => Order) public orders;

    // Events for monitoring contract interactions
    event OrderCreated(
        uint256 indexed orderId,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 price
    );
    event OrderCancelled(uint256 indexed orderId);
    event EquityTokenDeposited(uint256 indexed orderId, uint256 amount);
    event TransactionExecuted(
        uint256 indexed orderId,
        address newOwner,
        uint256 amount
    );
    event OrderModified(uint256 indexed orderId);
    event OrderUpdated(
        uint256 indexed orderId,
        address indexed tokenAddress,
        uint256 tokenAmount,
        uint256 price
    );

    constructor(IERC20 _coinToken, address _bank) {
        coinToken = _coinToken;
        bank = _bank;
    }

    function createOrder(
        uint256 _price,
        address _tokenAddress,
        uint256 _tokenAmount
    ) external {
        // Generate a unique orderId based on inputs and timestamp
        uint256 orderId = uint256(
            keccak256(
                abi.encodePacked(
                    _tokenAddress,
                    _tokenAmount,
                    _price,
                    msg.sender,
                    block.timestamp
                )
            )
        );

        orders[orderId] = Order({
            orderOwner: msg.sender,
            tokenAddress: _tokenAddress,
            tokenAmount: _tokenAmount,
            pricePerToken: _price,
            ppraFee: true
        });
        emit OrderCreated(orderId, msg.sender, _tokenAmount, _price);
    }

    function cancelOrder(uint256 _orderId) external {
        Order storage order = orders[_orderId];
        if (!(msg.sender == order.orderOwner || msg.sender == bank)) {
            revert NotAuthorizedToCancelOrder();
        }

        delete orders[_orderId];

        emit OrderCancelled(_orderId);
    }

    function cancelOrderByTokenOwner(uint256 _orderId) external {
        Order storage order = orders[_orderId];
        IAkcjaToken akcjaToken = IAkcjaToken(order.tokenAddress);

        if (!(msg.sender == akcjaToken.owner() || msg.sender == bank)) {
            revert NotAuthorizedToCancelOrder();
        }

        delete orders[_orderId];
    }

    // Buyer has to approve the contract to spend the stable coin
    // Seller has to approve the contract to spend the equity token

    function transact(uint _orderId) external {
        Order memory order = orders[_orderId];
        uint256 totalOrderAmount = order.pricePerToken * order.tokenAmount;
        address stable = address(coinToken);
        address buyer = orders[_orderId].orderOwner;

        assembly{

                mstore(0x00, hex"23b872dd") 
                mstore(0x04, buyer) 
                mstore(0x24, caller()) 
                mstore(0x44, totalOrderAmount) 

                // Execute the transfer
                if iszero(call(gas(), stable, 0, 0x00, 0x64, 0, 0)) {
                    revert(0, 0)
                }
    
        }
    
        uint256 amount = order.tokenAmount;
        address token = order.tokenAddress;
         assembly{
      
                mstore(0x00, hex"23b872dd") 
                mstore(0x04, caller()) 
                mstore(0x24, buyer) 
                mstore(0x44, amount) 

                // Execute the transfer
                if iszero(call(gas(), token, 0, 0x00, 0x64, 0, 0)) {
                    revert(0, 0)
                }
            }
     
        // Void order
        delete orders[_orderId];

        emit TransactionExecuted(_orderId, buyer, totalOrderAmount);
    }
}
