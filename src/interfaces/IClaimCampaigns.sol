//SPDX-License-Identifier:MIT
pragma solidity 0.8.19;

//@note All structs are defined in https://etherscan.io/address/0xBc452fdC8F851d7c5B72e1Fe74DFB63bb793D511#code

enum TokenLockup {
    Unlocked,
    Locked,
    Vesting
  }

  struct Campaign {
    address manager;
    address token;
    uint256 amount;
    uint256 end;
    TokenLockup tokenLockup;
    bytes32 root;
  }

  struct Donation {
    address tokenLocker;
    uint256 amount;
    uint256 rate;
    uint256 start;
    uint256 cliff;
    uint256 period;
}

struct ClaimLockup {
    address tokenLocker;
    uint256 start;
    uint256 cliff;
    uint256 period;
    uint256 periods;
}
interface IClaimCampaigns{

    function createLockedCampaign(
        bytes16 id,
        Campaign memory campaign,
        ClaimLockup memory claimLockup,
        Donation memory donation
    ) external;

    function cancelCampaign(bytes16 campaignId) external;
}

interface ILockupPlans {
  function createPlan(
    address recipient,
    address token,
    uint256 amount,
    uint256 start,
    uint256 cliff,
    uint256 rate,
    uint256 period
  ) external;
}

interface IVestingPlans {
    function createPlan(
    address recipient,
    address token,
    uint256 amount,
    uint256 start,
    uint256 cliff,
    uint256 rate,
    uint256 period,
    address vestingAdmin,
    bool adminTransferOBO
  ) external;
}