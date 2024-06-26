# POC Database

## Description
Purpose of this repo is to add a POC along with an article that explains the attack, engineering flaws that led to that attack etc. I will try to add a deep dive chapter on every POC attached to this database. 

---

## Attacks

| No. | Protocol | Date | Description | POC | Article | Author |
|-----|----------|------|-------------|-----|---------|--------|
| 1   | [Enzyme Finance](https://etherscan.io/address/0xcd6ca2f0d0c182C5049D9A1F65cDe51A706ae142)  | 18 Aug 23| Override ignores checks on base contract  | [01-EnzymeFinanceBounty0823](./test/01-EnzymeFinanceBounty0823.t.sol) | [Article](https://medium.com/@0kage/hack-series-deep-dive-chapter-1-enzyme-finance-90f4d85c067e)| 0Kage  |
| 2   | [Affine](https://etherscan.io/address/0xcd6ca2f0d0c182C5049D9A1F65cDe51A706ae142)  | 17 Feb 24| Missing access checks  | [02-AffineExploit0224](./test/02-AffineExploit0224.t.sol) | [Article](https://medium.com/@0kage/hack-series-deep-dive-chapter-2-affine-da2d7b0bbefd)| 0Kage  |
| 3   | [Barley Finance](https://etherscan.io/address/0x04c80bb477890f3021f03b068238836ee20aa0b8)  | 04 Mar 24| Flash loan re-entrancy  | [03-BarleyExploit0324](./test/03-BarleyExploit0324.t.sol) | [Article](https://medium.com/@0kage/0kage-diaries-chapter-3-barley-finance-180440407fda)| 0Kage  |
| 4   | [Transit Finance](https://bscscan.com/address/0x00000047bB99ea4D791bb749D970DE71EE0b1A34)  | 07 Apr 24| Fake Uniswap pool  | [04-TransitFinance1223](./test/04-TransitFinance1223.t.sol) | [Article](https://medium.com/@0kage/0kage-diaries-chapter-4-transit-finance-cb043307b97f)| 0Kage  |
| 4   | [Hedgey Finance](https://etherscan.io/address/0xBc452fdC8F851d7c5B72e1Fe74DFB63bb793D511#readContract)  | 09 Apr 24| Orphaned Spending Approval  | [05-HedgeyFinance0424](./test/05-HedgeyFinance0424.t.sol) | [Article](https://medium.com/@0kage/0kage-diaries-chapter-5-hedgey-finance-4da4ade97dc7)| 0Kage  |

