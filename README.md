# SaaS Revenue Risk Detection & Churn Reduction Strategy

##  Key Business Problem

SaaS businesses often rely heavily on a small number of high-value customers.
This creates significant revenue risk if those customers churn.

This project analyzes SaaS data to identify:

* Revenue concentration risk
* Churn drivers
* High-value accounts at risk

---

##  Key Business Risk Identified

* **83% of total revenue comes from top 20% of accounts**
* **₹82K (~16% of total MRR) is currently at risk** due to low engagement
* Weak relationship between engagement and revenue (**correlation = 0.20**)

* **Loss of a few high-value accounts can significantly impact overall revenue.**

---

##  Objective

* Identify revenue concentration across accounts
* Detect high-value, low-engagement accounts at risk
* Analyze churn patterns across segments
* Provide data-driven insights for retention strategy

---

##  Dataset Overview

* 700+ Users
* 180 Accounts
* 200+ Subscriptions
* 1200+ Product Events

---

##  Key Insights

### 1. Revenue Concentration

Top 20% of accounts contribute **83% of total revenue**, indicating high dependency on a small customer base.

### 2. Revenue at Risk

High-value accounts with low engagement contribute **₹82K revenue at risk**, requiring immediate attention.

### 3. Engagement vs Revenue

Correlation between engagement and revenue is **0.20**, suggesting engagement alone is not a strong predictor of revenue.

### 4. Segment Contribution

Enterprise segment contributes ~74% of total revenue, making it the most critical segment for retention.

---

##  Recommended Actions

* Prioritize retention efforts for high-value enterprise accounts
* Monitor low-engagement accounts proactively
* Trigger alerts for accounts inactive for more than 30 days
* Improve feature adoption through onboarding and engagement strategies
* Focus on reducing churn before renewal cycles

---

##  Business Impact

* Reduces risk of revenue loss from key accounts
* Enables proactive churn prevention
* Improves decision-making for customer success teams
* Highlights growth opportunities in underperforming segments

---

##  Tools & Technologies

* SQL (data extraction and transformation)
* Python (Pandas, Matplotlib for analysis)
* Power BI (dashboard and visualization)

---

##  Dashboard Preview
![executive](https://github.com/user-attachments/assets/7afc31bc-e283-491a-9659-5f21205f0f12)
![churn](https://github.com/user-attachments/assets/d108d7f9-203d-4eb6-afb7-a250ba0838c4)
![revenue](https://github.com/user-attachments/assets/e28a8c9c-560b-444a-bd1b-29227bc7e2c2)
![risk](https://github.com/user-attachments/assets/93fd861b-02c1-4ee5-96d2-b7c701926d11)

---

##  Conclusion

This project demonstrates how data analysis can be used to identify revenue risk and support churn reduction strategies in a SaaS business.
It highlights the importance of focusing on high-value accounts and proactive engagement to ensure revenue stability.
