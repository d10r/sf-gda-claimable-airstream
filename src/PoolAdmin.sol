// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {
    ISuperfluid, ISuperToken, ISuperfluidPool, PoolConfig
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { SuperTokenV1Library } from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";

using SuperTokenV1Library for ISuperToken;

contract PoolAdmin {
    error UnAuthorized();
    error UnitsOverflow();

    ISuperfluidPool public immutable pool;
    ISuperToken public immutable superToken;
    // constant amount of pool units to be assigned
    uint128 public immutable totalUnits;
    // the distributing account, to which we also assign excess units
    address public immutable distributor;
    address public immutable claimController;

    constructor(ISuperToken superToken_, uint128 totalUnits_, address distributor_, address claimController_) {
        superToken = superToken_;
        totalUnits = totalUnits_;
        distributor = distributor_;
        claimController = claimController_;

        pool = superToken.createPool(
            address(this), // pool admin
            PoolConfig({
                transferabilityForUnitsOwner: true,
                distributionFromAnyAddress: true
            })
        );

        pool.updateMemberUnits(distributor, totalUnits_);
    }

    function claimFor(address account, uint128 units) public {
        if (msg.sender != claimController) revert UnAuthorized();

        uint128 distributorUnits = pool.getUnits(distributor);
        if (units > distributorUnits) revert UnitsOverflow();

        pool.updateMemberUnits(account, units);
        pool.updateMemberUnits(distributor, distributorUnits - units);
    }
}