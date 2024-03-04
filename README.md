# POC Database

## Description
Purpose of this repo is to add a POC along with an article that explains the attack, engineering flaws that led to that attack etc. I will try to add a deep dive chapter on every POC attached to this database. 

---

## Attacks

| No. | Protocol | Date | Description | POC | Article | Author |
|-----|----------|------|-------------|-----|---------|--------|
| 1   | [Enzyme Finance](https://etherscan.io/address/0xcd6ca2f0d0c182C5049D9A1F65cDe51A706ae142)  | 18 Aug 23| Override ignores checks on base contract  | [01-EnzymeFinanceBounty0823](./test/01-EnzymeFinanceBounty0823.t.sol) | [Article](https://medium.com/@0kage/hack-series-deep-dive-chapter-1-enzyme-finance-90f4d85c067e)| 0Kage  |
| 2   | [Affine](https://etherscan.io/address/0xcd6ca2f0d0c182C5049D9A1F65cDe51A706ae142)  | 17 Feb 24| Missing access checks  | [02-AffineExploit0224](./test/02-AffineExploit0224.t.sol) | [Article](https://medium.com/@0kage/hack-series-deep-dive-chapter-2-affine-da2d7b0bbefd)| 0Kage  |
| 3   | [Barley Finance](https://etherscan.io/address/0x04c80bb477890f3021f03b068238836ee20aa0b8)  | 04 Mar 24| Flash loan re-entrancy  | [03-BarleyExploit0324](./test/03-BarleyExploit0324.m.t.sol) | [Article]https://medium.com/@0kage/0kage-diaries-chapter-3-barley-finance-180440407fda)| 0Kage  |

