# swap-contract
Bear Builder - Swap contract example

This contract and the accompanying test suite (index.mjs)
were written for the Reach Bear Builder Challenge.
It serves as an example of a contract that can be used to swap network tokens for an ASA token,
by allowing any user to deposit the specified ASA token, which can only be withdrawn by the designated addressee.

This contract takes a slightly different approach to a traditional swap.
It uses an API to allow any user to connect to the contract and deposit the ASA token.
Anyone can deposit tokens for any address using the deposit() API call
as long as that address has opted-in to the contract.
Any user may then withdraw the ASA token(s) allocated to them using the withdraw() API call.
All ASA token balances are tracked in a Map.
When the contract is ended, by calling the endContract API method,
the balance of network tokens and remaining ASA tokens are transferred to the Deployer.

APIs available:
* join() - used to opt a user in to the contract
* deposit(amount, address) - deposit (amount) tokens to (address)
* withdraw(amount) - withdraw (amount) tokens allocated to the address calling the API function
* endContract - only callable by a designated addressee or the Deployer to end the contract and send all remaining balances to the deployer

Views available:
* getUserBalance(address) - Returns the amount of tokens held by the contract for (address)

The deployer, or any address designated during deployment, may end the contract by calling the endContract API function.

![Screenshot of program terminal output](screenshot.png?raw=true "Screenshot of program terminal output")
