const lpMath = require('./lpMath.js')

const a = 1000
const b = 2000
const price = 2

const sqrtRatioX96 = Math.sqrt(price)

const sqrtRatioAX96 = Math.sqrt(a)
const sqrtRatioBX96 = Math.sqrt(b)

const liquidity = lpMath.getLiquidityForAmounts(sqrtRatioX96, sqrtRatioAX96, sqrtRatioBX96, 1, 1000)

console.log(`Liquidity: ${liquidity}`)
console.log(`Price Sqrt: ${Math.sqrt(price)}`)

for (let price = a - 50; price <= b + 50; price = price + 50) {
  console.log(price, lpMath.getAmountsForLiquidity(Math.sqrt(price), sqrtRatioAX96, sqrtRatioBX96, liquidity))
}