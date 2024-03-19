// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import { ERC1820RegistryCompiled } from "@superfluid-finance/ethereum-contracts/contracts/libs/ERC1820RegistryCompiled.sol";
import { SuperfluidFrameworkDeployer } from "@superfluid-finance/ethereum-contracts/contracts/utils/SuperfluidFrameworkDeployer.sol";

import {
    ISuperfluid, ISuperToken, ISuperfluidPool, PoolConfig
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { SuperTokenV1Library } from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";

import { PoolAdmin } from "../src/PoolAdmin.sol";

using SuperTokenV1Library for ISuperToken;

contract SFAppTest is Test {
    SuperfluidFrameworkDeployer.Framework internal sf;
    PoolAdmin _app;
    ISuperToken superToken;
    uint128 constant TOTAL_UNITS = 1_000_000;
    int96 constant DISTRIBUTION_FLOW_RATE = 1e18; // 1 token per second = ~2.5M token per month
    address constant PRINTER = address(1971);
    address constant CLAIM_CONTROLLER = address(0xc1);
    address constant ALICE = address(0x1);

    function setUp() public {
        // deploy SF framework
        vm.etch(ERC1820RegistryCompiled.at, ERC1820RegistryCompiled.bin);
        SuperfluidFrameworkDeployer deployer = new SuperfluidFrameworkDeployer();
        deployer.deployTestFramework();
        sf = deployer.getFramework();

        superToken = deployer.deployPureSuperToken("Token", "TOK", 2**200);
        superToken.transfer(PRINTER, 10_000_000 * 1e18);
        _app = new PoolAdmin(superToken, TOTAL_UNITS, PRINTER, CLAIM_CONTROLLER);
    }

    function _checkState(string memory msg) internal {
        console.log("========", msg, "========");
        console.log("Pool totalUnits", _app.pool().getTotalUnits());
        console.log("PRINTER units", _app.pool().getUnits(PRINTER));
        console.log("ALICE units", _app.pool().getUnits(ALICE));
        console.log("PRINTER balance", superToken.balanceOf(PRINTER));
        console.log("ALICE balance", superToken.balanceOf(ALICE));
        console.log("ADMIN balance", superToken.balanceOf(_app.pool().admin()));
        assertEq(_app.pool().getTotalUnits(), TOTAL_UNITS, "total units wrong");
    }

    // nothing is distributed if nothing was claimed
    function testDistributeBeforeClaim() public {
        _checkState("before distributeFlow");
        vm.startPrank(PRINTER);
        superToken.connectPool(_app.pool());
        superToken.distributeFlow(PRINTER, _app.pool(), DISTRIBUTION_FLOW_RATE);
        vm.stopPrank();

        _checkState("before warp");
        vm.warp(block.timestamp + 1 days);
        _checkState("after warp");
    }

    function testClaim() public {
        vm.startPrank(ALICE);
        superToken.connectPool(_app.pool());
        vm.stopPrank();

        vm.startPrank(PRINTER);
        superToken.connectPool(_app.pool());
        superToken.distributeFlow(PRINTER, _app.pool(), DISTRIBUTION_FLOW_RATE);
        vm.stopPrank();

        uint128 aliceUnits = 50_000;

        _checkState("Before claim");
        vm.startPrank(CLAIM_CONTROLLER);
        _app.claimFor(ALICE, aliceUnits);
        vm.stopPrank();
        _checkState("After claim");

        vm.warp(block.timestamp + 1 days);
        _checkState("After warp");
    }
}
