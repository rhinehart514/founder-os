# Unit Economics Reference

Formulas, benchmarks, and examples for solo founder businesses.

## Core formulas

### Monthly Recurring Revenue (MRR)
```
MRR = paying_users x price_per_user
ARR = MRR x 12
```

### Customer Acquisition Cost (CAC)
```
CAC = total_acquisition_spend / new_customers_acquired
```
For solo founders: include your time at opportunity cost. 10 hours writing content at $100/hr effective rate = $1000 CAC for however many users it brings.

### Customer Lifetime Value (LTV)
```
LTV = ARPU x average_lifetime_months
average_lifetime_months = 1 / monthly_churn_rate
```
Example: $19/mo price, 5% monthly churn
- Average lifetime = 1/0.05 = 20 months
- LTV = $19 x 20 = $380

### LTV:CAC Ratio
```
LTV_CAC = LTV / CAC
```
- Below 1.0: losing money on every customer
- 1.0-3.0: unsustainable without fixing acquisition or retention
- 3.0+: healthy unit economics
- 5.0+: under-investing in growth (or numbers are wrong)

### Payback Period
```
payback_months = CAC / monthly_revenue_per_user
```
Solo founder target: under 3 months. If payback exceeds 6 months, you're financing customer acquisition out of pocket for too long.

## Churn benchmarks

| Segment | Monthly churn | Annual churn | Source |
|---------|-------------|-------------|--------|
| SMB SaaS | 3-7% | 30-60% | Industry avg |
| Mid-market SaaS | 1-3% | 10-30% | Industry avg |
| Enterprise SaaS | 0.5-1% | 5-10% | Industry avg |
| Solo founder default | 5% | 46% | Conservative assumption |

**Use 5% monthly as default** until you have real retention data. Optimistic churn assumptions are the most common unit economics lie.

## Worked example

Product: Developer tool at $29/mo
Monthly churn: 5% (assumed, no data)
CAC: $150 (estimated from content marketing time + ad spend)

```
Average lifetime = 1/0.05 = 20 months
LTV = $29 x 20 = $580
LTV:CAC = $580 / $150 = 3.87 (healthy)
Payback = $150 / $29 = 5.2 months (borderline)
```

At 10 users: MRR = $290, ARR = $3,480
At 50 users: MRR = $1,450, ARR = $17,400
At 100 users: MRR = $2,900, ARR = $34,800

## Red flags in unit economics

- **LTV based on assumed 36-month lifetime** with no retention data. Use 12 months maximum as assumption.
- **CAC = $0 "because organic."** Your time has a cost.
- **Ignoring infrastructure costs per user.** AI products especially: API costs can eat margin.
- **Expansion revenue in base case.** Only count if you have evidence users upgrade.
- **Blended CAC hiding a bad channel.** Break CAC out per channel. One good channel hides three bad ones.

## The solo founder economics test

Quick pass/fail for whether the business math works:

1. Can you get to $1k MRR with < 100 users? (If not, price is too low)
2. Is payback under 6 months? (If not, CAC is too high or price too low)
3. Would 5% monthly churn kill you? (If yes, you need retention work before growth)
4. Can you acquire users with < 10 hours/week of your time? (If not, the channel doesn't scale)
