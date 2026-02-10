# Metric: AI Bookings Participation Rate

## 1. Business Definition
This metric tracks the percentage of sales representatives who have successfully sold **all three** of our strategic AI product lines. It measures cross-sell competency and adoption of the full AI suite.

* **Metric Name:** AI Bookings Participation Rate
* **Numerator:** Count of Reps who have at least **1 Won Booking** in **ALL** three categories (Copilot + AI Agents + QA).
* **Denominator:** Total Count of Reps who have at least **1 Won Booking** of *any* kind (Total Active Booking Reps).
* **Formula:** `(Reps with All 3 Flags / Total Active Reps) * 100`

---

## 2. Product Mapping & Logic
To qualify as a "Triple Crown" winner, a rep must have a closed-won opportunity in each of the following buckets:

| Product Bucket | Raw Product Names (Database) |
| :--- | :--- |
| **1. Copilot** | `Copilot` |
| **2. AI Agents** | `Ultimate`, `Ultimate_AR`, `Zendesk_AR` |
| **3. QA** | `QA` |

### Critical Filters
The following filters are applied to **all** data to ensure data quality:
* **Stage:** `Closed Won` (Is_Won = True)
* **Financials:** `Product_ARR_USD > 0` (No zero-dollar deals)
* **Type:** `Opportunity_Is_Commissionable = TRUE` (Excludes non-comp/admin deals)
* **Timeframe:** `Date_Label = 'today'` (Current Snapshot)

## [Output](https://docs.google.com/spreadsheets/d/1YkLlRivWn1h5v0wFyi030ICAG6ozbcrIjLG82J_QRM0/edit?usp=sharing)
