# swap-contract
Bear Builder - Swap contract example

This contract and the accompanying test suite (index.mjs)
were written for the Reach Bear Builder Challenge.
It serves as an example of a contract that can be used to transfer network tokens,
by allowing any user to deposit tokens that can only be withdrawn by the designated addressee.

This contract takes a slightly different approach to a traditional swap.
It uses an API to allow any user to connect to the contract and deposit tokens.
Anyone can deposit tokens for any address as long as that address has opted-in to the contract,
and all balances are tracked in a Map.
Any user may then withdraw the tokens allocated to them using an API call.

APIs available:
* join() - used to opt a user in to the contract
* deposit(amount, address) - deposit (amount) tokens to (address)
* withdraw(amount) - withdraw (amount) tokens allocated to the address calling the API function

Views available:
* getUserBalance(address) - Returns the amount of tokens held by the contract for (address)

The deployer, or any address specified during deployment, may end the contract by calling an endContract API function.

![Screenshot of program terminal output](screenshot.png?raw=true "Screenshot of program terminal output")
