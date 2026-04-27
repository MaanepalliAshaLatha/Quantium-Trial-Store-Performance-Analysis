# Quantium Trial Store Performance Analysis

**Quantium Virtual Internship — Task 2 | Retail Strategy & Analytics**

A/B testing analysis to evaluate whether a new chip category store layout should be rolled out across all stores, based on trial performance in stores 77, 86, and 88.

---

## Business Problem

The Category Manager (Julia) implemented a new store layout in 3 trial stores and needs a data-driven recommendation: **should this layout be rolled out to all stores?**

To answer this fairly, each trial store was matched to a similar control store that did NOT receive the new layout. Performance was then compared during the trial period (Feb–Apr 2019) against the pre-trial baseline (Jul 2018–Jan 2019).

---

## Tools Used

| Tool | Purpose |
|------|---------|
| MySQL | Data preparation, metric calculation, control store scoring |
| Power BI | Trial vs control line chart visualisations |

---

## Methodology

### Step 1 — Monthly Metrics
Calculated per store per month:
- Total sales revenue
- Unique customer count
- Transactions per customer
- Average price per unit

### Step 2 — Control Store Selection
Used **Magnitude Distance Scoring** to find the most similar store for each trial store based on pre-trial monthly sales patterns.

**Formula:**
```
Score = 1 - (abs_diff - min_diff) / (max_diff - min_diff)
```
Score of **1.0** = perfect match. Score of **0.0** = completely different.

### Step 3 — Scaling
Applied a scaling factor to normalise for natural size differences between stores:
```
Scaling Factor = Sum(Trial Store Pre-Trial Sales) / Sum(Control Store Pre-Trial Sales)
```

### Step 4 — Trial Assessment
Compared scaled control store sales vs trial store sales during Feb–Apr 2019. Analysed both total sales and customer count to identify the driver of any observed change.

---

## Control Store Matching Results

| Trial Store | Control Store | Magnitude Score | Scaling Factor |
|-------------|--------------|----------------|----------------|
| Store 77 | Store 53 | 0.9859 | 1.0042 |
| Store 86 | Store 10 | 0.9386 | 0.9526 |
| Store 88 | Store 56 | 0.9123 | 0.8621 |

---

## Key SQL Queries

### Monthly Metrics Table
```sql
CREATE VIEW monthly_metrics AS
SELECT 
    STORE_NBR,
    CONCAT(YEAR(txn_date), LPAD(MONTH(txn_date), 2, '0')) AS YEARMONTH,
    SUM(tot_sales) AS totSales,
    COUNT(DISTINCT lylty_card_nbr) AS nCustomers,
    COUNT(txn_id) / COUNT(DISTINCT lylty_card_nbr) AS nTxnPerCust,
    SUM(tot_sales) / SUM(prod_qty) AS avgPricePerUnit
FROM qvi_data
GROUP BY STORE_NBR, YEARMONTH
ORDER BY STORE_NBR, YEARMONTH;
```

### Pre-Trial Filter (Stores with Full 7-Month Observation)
```sql
CREATE VIEW pre_trial AS
SELECT * FROM monthly_metrics
WHERE YEARMONTH < 201902
AND STORE_NBR IN (
    SELECT STORE_NBR FROM monthly_metrics
    WHERE YEARMONTH < 201902
    GROUP BY STORE_NBR
    HAVING COUNT(*) = 7
);
```

### Magnitude Distance Scoring (Example: Store 77)
```sql
SELECT 
    control_store,
    AVG(1 - (abs_diff - min_diff) / (max_diff - min_diff)) AS avg_magnitude_score
FROM (
    SELECT 
        trial_store, control_store, YEARMONTH, abs_diff,
        MIN(abs_diff) OVER (PARTITION BY YEARMONTH) AS min_diff,
        MAX(abs_diff) OVER (PARTITION BY YEARMONTH) AS max_diff
    FROM (
        SELECT
            a.STORE_NBR AS trial_store,
            b.STORE_NBR AS control_store,
            a.YEARMONTH,
            ABS(a.totSales - b.totSales) AS abs_diff
        FROM (SELECT * FROM pre_trial WHERE store_nbr = 77) AS a
        JOIN (SELECT * FROM pre_trial WHERE store_nbr <> 77) AS b
        ON a.YEARMONTH = b.YEARMONTH
    ) AS diffs
) AS magnitude_diff
GROUP BY control_store
ORDER BY avg_magnitude_score DESC;
```

### Trial Period Comparison (Store 77)
```sql
SELECT
    a.YEARMONTH,
    a.Store_77_totSales,
    a.Store_77_nCustomers,
    a.Store_77_nTxnPerCust,
    b.scaled_control_sales,
    b.Store_53_nCustomers,
    b.Store_53_nTxnPerCust,
    ABS(Store_77_totSales - scaled_control_sales) AS diff
FROM (
    SELECT YEARMONTH,
        SUM(CASE WHEN store_nbr = 77 THEN totSales END) AS Store_77_totSales,
        SUM(CASE WHEN store_nbr = 77 THEN nCustomers END) AS Store_77_nCustomers,
        AVG(CASE WHEN store_nbr = 77 THEN nTxnPerCust END) AS Store_77_nTxnPerCust
    FROM monthly_metrics
    WHERE YEARMONTH IN (201902, 201903, 201904)
    GROUP BY YEARMONTH
) AS a
JOIN (
    SELECT YEARMONTH,
        SUM(CASE WHEN store_nbr = 53 THEN totSales END) * 1.0042 AS scaled_control_sales,
        SUM(CASE WHEN store_nbr = 53 THEN nCustomers END) AS Store_53_nCustomers,
        AVG(CASE WHEN store_nbr = 53 THEN nTxnPerCust END) AS Store_53_nTxnPerCust
    FROM monthly_metrics
    WHERE YEARMONTH IN (201902, 201903, 201904)
    GROUP BY YEARMONTH
) AS b
ON a.YEARMONTH = b.YEARMONTH;
```

---

## Trial Results

### Store 77 — Positive Trial Effect ✅

| Month | Store 77 Sales | Scaled Control | Difference | Customers 77 | Customers 53 |
|-------|---------------|---------------|------------|-------------|-------------|
| Feb 2019 | 235.00 | 179.84 | +55.16 | 45 | 36 |
| Mar 2019 | 278.50 | 226.74 | +51.76 | 50 | 45 |
| Apr 2019 | 263.50 | 228.75 | +34.75 | 47 | 39 |

**Driver:** Higher customer footfall (+20–25%) — not higher spend per visit.

---

### Store 86 — Inconsistent Results ⚠️

| Month | Store 86 Sales | Scaled Control | Difference |
|-------|---------------|---------------|------------|
| Feb 2019 | 822.20 | 812.53 | +9.67 |
| Mar 2019 | 1,004.00 | 821.10 | +182.90 |
| Apr 2019 | 832.00 | 710.79 | +121.21 |

**Finding:** Near-zero impact in February with high variance across months. Inconsistent results make rollout decision unreliable.

---

### Store 88 — Novelty Effect, No Sustained Benefit ❌

| Month | Store 88 Sales | Scaled Control | Difference | Customers 88 | Customers 56 |
|-------|---------------|---------------|------------|-------------|-------------|
| Feb 2019 | 801.00 | 540.19 | +260.81 | 72 | 75 |
| Mar 2019 | 633.00 | 602.95 | +30.05 | 59 | 82 |
| Apr 2019 | 554.60 | 657.43 | -102.83 | 51 | 85 |

**Finding:** Sharp novelty spike in February followed by rapid decay. Customer count declined every month while control store grew. Below control by April.

---

## Recommendations

| Store | Recommendation | Reason |
|-------|---------------|--------|
| Store 77 | ✅ **Proceed with rollout** to similar stores | Consistent sales uplift driven by increased footfall across all 3 trial months |
| Store 86 | ⚠️ **Investigate further** before decision | Inconsistent results — February near zero, possible delayed implementation |
| Store 88 | ❌ **Do not roll out** to similar stores | Novelty effect faded rapidly, customer count declined below control by April |

---

## Final Conclusion

The trial results show mixed outcomes across three stores. **Store 77 demonstrated the most reliable positive impact** — consistent customer footfall increase across all trial months with sales remaining above the scaled control throughout the period. This store profile should be prioritised for rollout.

Store 86 requires further investigation before a confident decision. Store 88 showed no sustainable benefit and risks disrupting existing customer behaviour if rolled out further.

---

## Project Structure

```
Quantium-Trial-Store-Performance-Analysis/
│
├── data/
│   ├── QVI_data.csv                    # Transaction + customer data
│   ├── store77_vs_53.csv               # Monthly comparison data
│   ├── store86_vs_10.csv
│   └── store88_vs_56.csv
│
├── sql/
│   └── task2_queries.sql               # All SQL queries used
│
├── visualisations/
│   ├── chart_store77.png               # Trial vs control line chart
│   ├── chart_store86.png
│   └── chart_store88.png
│
└── report/
    └── Quantium_Task2_Report.pdf       # Final report submitted to Forage
```

---

## Author

**Asha Latha Maanepalli**
- GitHub: [MaanepalliAshaLatha](https://github.com/MaanepalliAshaLatha)
- LinkedIn: [maanepalli-asha-latha](https://linkedin.com/in/maanepalli-asha-latha041025269/)

*Quantium Virtual Internship — Retail Strategy and Analytics*
