'reach 0.1';
'use strict';

const Params = Tuple(Address); // authAddress
const myFromMaybe = (m) => fromMaybe(m, (() => 0), ((x) => x));

export const main = Reach.App(() => {

  setOptions({ connectors: [ ALGO ], untrustworthyMaps: true });
  
  const Deployer = Participant('Deployer', {
    setParams: Fun([], Params), // set some basic contract parameters, specifically what address can end the contract
  });
  
  const UserAPI = API('UserAPI', {
    join: Fun([], Null),  // opt in to contract, needed before we can give tokens to an address in the map
    deposit: Fun([UInt, Address], UInt), // returns updated current balance for Address and adds amount to Address's balance
    withdraw: Fun([UInt], UInt), // returns updated current balance
  });

  const AdminAPI = API('AdminAPI', {
    endContract: Fun([], Bool), // exit parallelReduce and end contract
  });

  const V = View({
    getUserBalance: Fun([Address], UInt), // view the balance of tokens for a user in the contract
  });

  init();

  Deployer.only(() => {
    const [ AuthAccount ] = declassify(interact.setParams());
  });
  Deployer.publish(AuthAccount);

  // Map to track balances for users
  const userBalances = new Map(UInt);

  // View to see balances of users in userBalances map
  V.getUserBalance.set((m) => myFromMaybe(userBalances[m]));

  const [ done, totalDeposits ] = parallelReduce([ false, 0 ])
      .invariant(balance() >= totalDeposits)
      .while(!done)
      .api(
        UserAPI.join,
        () => {},
        () => 0,
        (returnFunc) => {
          returnFunc(null);
          return [ done, totalDeposits ];
        }
      )
      .api(
        UserAPI.deposit,
        (depositAmt,_) => {
          assume(depositAmt > 0);
        },
        (depositAmt,_) => depositAmt,
        (depositAmt,depositAddr,returnFunc) => {
          require(depositAmt > 0);

          const curBalance = myFromMaybe(userBalances[depositAddr]);
          userBalances[depositAddr] = curBalance + depositAmt;

          returnFunc(myFromMaybe(userBalances[depositAddr]));
          return [ done, totalDeposits + depositAmt ];
        }
      )
      .api(
        UserAPI.withdraw,
        (withdrawAmt) => {
          assume(withdrawAmt > 0);
          assume(withdrawAmt <= balance());
        },
        (_) => 0,
        (withdrawAmt,returnFunc) => {
          require(withdrawAmt > 0);
          require(withdrawAmt <= balance());

          const curBalance = myFromMaybe(userBalances[this]);
          const maxWithdrawAmt = array(UInt, [ curBalance , withdrawAmt ]).min();
          userBalances[this] = curBalance - maxWithdrawAmt;

          returnFunc(myFromMaybe(userBalances[this]));
          transfer(maxWithdrawAmt).to(this);

          return [ done, totalDeposits - maxWithdrawAmt ];
        }
      )
      .api(
        AdminAPI.endContract,
        () => {
          assume(this == Deployer);
        },
        () => 0,
        (returnFunc) => {
          require(this == Deployer);
          returnFunc(true);

          return [ true, totalDeposits ];
        }
      );

  transfer(balance()).to(Deployer);
  commit();

  exit();
});
