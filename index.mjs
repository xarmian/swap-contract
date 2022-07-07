import {loadStdlib} from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib();

(async () => {
  const startingBalance = stdlib.parseCurrency(100);
  const getBalance = async (who) => stdlib.formatCurrency(await stdlib.balanceOf(who), 4);

  const [ accAlice, accBob ] = await stdlib.newTestAccounts(2, startingBalance);
  const addrAlice = stdlib.formatAddress(accAlice.getAddress());
  const addrBob = stdlib.formatAddress(accBob.getAddress());

  console.log('Accounts for Alice and Bob have been generated.');
  console.log(`Alice has a starting balance of ${await getBalance(accAlice)} tokens and address ${addrAlice}`);
  console.log(`Bob has a starting balance of ${await getBalance(accBob)} tokens and address ${addrBob}`);

  console.log('Alice is deploying the swap contract...');
  const ctcAlice = await accAlice.contract(backend);

  ctcAlice.p.Deployer({
    setParams: function() {
      return [ addrAlice ];
    }
  });

  console.log(`Bob is joining the swap contract and opting in...`);
  const ctcBob = accBob.contract(backend, ctcAlice.getInfo());
  await ctcBob.a.UserAPI.join();

  console.log(`Alice sends 10 tokens to the swap contract under Bob's address to claim the funds.`);
  await ctcAlice.a.UserAPI.deposit(stdlib.parseCurrency(10),addrBob);

  const bobBalance = await ctcBob.v.getUserBalance(addrBob);
  console.log(`Bob can see his withdrawable balance in the contract is: ${stdlib.formatCurrency(bobBalance[1],4)}`);

  console.log(`Bob is withdrawing the tokens deposited by Alice`);
  const newBalance = await ctcBob.a.UserAPI.withdraw(bobBalance[1]);

  console.log(`Bob's new balance is ${await getBalance(accBob)}`);
  console.log(`Bob has ${stdlib.formatCurrency(newBalance,4)} remaining in the contract.`);

  console.log(`Alice's new balance is ${await getBalance(accAlice)}`);

  console.log(`Alice is ending the contract.. goodbye.`);
  await ctcAlice.a.AdminAPI.endContract();

  process.exit();
})();
