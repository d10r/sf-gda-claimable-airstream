## About

We previously prototyped a simple Merkle Distribution Stream solution, where `claim` just allocates units of a GDA.

In this prototype, we want to use the GDA such that it's configured for a distribution with a given max distribution flowrate, allowing async claims.
The claim verification is out of scope.

Components
- PoolAdmin contract
- Distributor (could also be an EOA)

## PoolAdmin contract

On deployment, creates a GDA pool for the defined SuperToken.

Has a function `claimFor` which lets a permissioned contract trigger the claiming for a given account.
The sender account could then be the entry point for the claiming account, and e.g. verify a Merkle proof.

Invariant: the pool always has `totalUnits` assigned. Unclaimed units belong to the distributor account.
Initially, all units belong to the distributor account.

## Distributor account

Can be an EOA or a contract.
Is expected to eventually do a flowDistribution of the defined flowrate.
The not-yet-claimed portion of the flowrate loops back to this account.

## Outcome

This allows to do flow distributions with async claiming.
Limitation: Those claiming earlier will get more, because there's no mechanism for stopping the distribution to specific receivers based on the time of their claiming.