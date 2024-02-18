// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {TOK} from "../src/NewTOK.sol";
import {StableCoin} from "../src/StableCoin.sol";
import {EquityToken} from "../src/EquityToken.sol";
import {AkcjaToken} from "../src/AkcjaToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NewTOKTest is Test {
    TOK public tok;
    StableCoin public stableCoin;
    EquityToken public equityToken;
    AkcjaToken public orlen;

    address public bank = address(0x1);
    address public buyer = address(0x2);
    address public seller = address(0x3);

    function setUp() public {
        stableCoin = new StableCoin(1000000000000000000000000000);
        tok = new TOK(IERC20(address(stableCoin)), bank);
        equityToken = new EquityToken();
        orlen = AkcjaToken(
            equityToken.createAkcja(
                "Orlen",
                "ORN",
                1000000000000000000000000000
            )
        );
        stableCoin.transfer(buyer, 1000000000000000000000000000);
        orlen.transfer(seller, 1000000000000000000000000000);
    }

    function test_createToken() public {
        address orlenAddr = equityToken.createAkcja(
            "Orlen",
            "ORN",
            1000000000000000000000000000
        );
        orlen = AkcjaToken(orlenAddr);
    }

    function test_name() public {
        assertEq(orlen.name(), "Orlen");
    }

    function test_ticker() public {
        assertEq(orlen.symbol(), "ORN");
    }

    function test_createOrder() public {
        vm.prank(buyer);
        tok.createOrder(100, address(orlen), 5);
    }

    function test_createAndCancel() public {
        vm.prank(buyer);
        tok.createOrder(100, address(orlen), 5);
        uint256 orderId = 26376681523822788268532602546208993976923143975760489275388391086567406736886; //hardcoded
        vm.prank(buyer);
        tok.cancelOrder(orderId);
    }

    function test_createAndCancelAsBank() public {
        vm.prank(bank);
        tok.createOrder(100, address(orlen), 5);
        uint256 orderId = 92741770184332299107859104128791210041573350679577771628459845585913255896106; //hardcoded
        vm.prank(bank);
        tok.cancelOrderByTokenOwner(orderId);
    }

    function test_fullFlow() public {
        // Approvals
        vm.prank(buyer);
        stableCoin.approve(address(tok), type(uint256).max);
        vm.prank(seller);
        orlen.approve(address(tok), type(uint256).max);

        vm.prank(buyer);
        tok.createOrder(100, address(orlen), 5);
        uint256 orderId = 26376681523822788268532602546208993976923143975760489275388391086567406736886; //hardcoded
        vm.prank(seller);
        tok.transact(orderId);
    }
}
