'reach 0.1';
'use strict';

const Params = Tuple(Address, Token); // authAddress, Token for swapping
const myFromMaybe = (m) => fromMaybe(m, (() => 0), ((x) => x));
const SWAP_FEE = 10000000; // 10 token swap fee

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
    const [ AuthAccount, SwpToken ] = declassify(interact.setParams());
  });
  Deployer.publish(AuthAccount, SwpToken);

  // Map to track balances for users
  const userBalances = new Map(UInt);

  // View to see balances of users in userBalances map
  V.getUserBalance.set((m) => myFromMaybe(userBalances[m]));

  const [ done, totalTokens, totalFees ] = parallelReduce([ false, 0, 0 ])
      .invariant(balance() >= totalFees)
      .invariant(balance(SwpToken) >= totalTokens)
      .while(!done)
      .paySpec([ SwpToken ])
      .api(
        UserAPI.join,
        () => {},
        () => [ 0, [ 0, SwpToken ] ],
        (returnFunc) => {
          returnFunc(null);
          return [ done, totalTokens, totalFees ];
        }
      )
      .api(
        UserAPI.deposit,
        (depositAmt,_) => {
          assume(depositAmt > 0);
        },
        (depositAmt,_) => [ 0, [ depositAmt, SwpToken ]],
        (depositAmt,depositAddr,returnFunc) => {
          require(depositAmt > 0);

          const curBalance = myFromMaybe(userBalances[depositAddr]);
          userBalances[depositAddr] = curBalance + depositAmt;

          returnFunc(myFromMaybe(userBalances[depositAddr]));
          return [ done, totalTokens + depositAmt, totalFees ];
        }
      )
      .api(
        UserAPI.withdraw,
        (withdrawAmt) => {
          assume(withdrawAmt > 0);
          assume(withdrawAmt <= balance(SwpToken));
        },
        (_) => [ SWAP_FEE, [ 0, SwpToken ] ],
        (withdrawAmt,returnFunc) => {
          require(withdrawAmt > 0);
          require(withdrawAmt <= balance(SwpToken));

          const curBalance = myFromMaybe(userBalances[this]);
          const maxWithdrawAmt = array(UInt, [ curBalance , withdrawAmt ]).min();
          userBalances[this] = curBalance - maxWithdrawAmt;

          returnFunc(myFromMaybe(userBalances[this]));
          transfer([0, [maxWithdrawAmt, SwpToken]]).to(this);

          return [ done, totalTokens - maxWithdrawAmt, totalFees + SWAP_FEE ];
        }
      )
      .api(
        AdminAPI.endContract,
        () => {
          assume(this == Deployer);
        },
        () => [ 0, [ 0, SwpToken ] ],
        (returnFunc) => {
          require(this == Deployer);
          returnFunc(true);

          return [ true, totalTokens, totalFees ];
        }
      );

      transfer(balance()).to(Deployer);
      transfer([ 0, [ balance(SwpToken), SwpToken ] ]).to(Deployer);
      commit();

  exit();
});
