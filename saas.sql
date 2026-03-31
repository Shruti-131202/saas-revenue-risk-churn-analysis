create database saas;
-- create table account
CREATE TABLE accounts (
    account_id INT PRIMARY KEY,
    account_name VARCHAR(100),
    segment VARCHAR(50),
    region VARCHAR(50),
    created_at DATETIME,
    plan VARCHAR(50),
    mrr DECIMAL(10,2)
);
-- user
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    account_id INT,
    email VARCHAR(100),
    role VARCHAR(50),
    country VARCHAR(50),
    created_at DATETIME,
    is_active varchar(50),
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);
-- subscription
CREATE TABLE subscriptions (
    subscription_id INT PRIMARY KEY,
    account_id INT,
    plan VARCHAR(50),
    mrr int,
    status_ VARCHAR(50),
    started_at DATETIME,
    ended_at DATETIME NULL,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);
-- events
CREATE TABLE events (
    event_id INT PRIMARY KEY,
    user_id INT,
    event_type VARCHAR(50),
    feature_name VARCHAR(50),
    occurred_at DATETIME,
   
   FOREIGN KEY (user_id) REFERENCES users(user_id)
);
-- 1 tabel count
select count(*) from users;
select count(*) from accounts;
select count(*) from subscriptions; 
select count(*) from events;
-- 2 Multiple subscriptions per account?
select account_id,count(*) from subscriptions group by account_id having count(*) > 1;
-- 3 More than one active subscription
select account_id, count(*) from subscriptions where status_ = "active" group by account_id having count(*) > 1;
-- 4 NULL checks
select * from subscriptions where mrr is null;
select  * from users where account_id is null;
select * from events where user_id is null;
-- 5 Active subscriptions with ended_at not null?
select * from subscriptions where status_ = "active" And ended_at is not null;
-- 6 Cancelled but ended_at is null?
select * from subscriptions where status_ = "canceled" And ended_at is null;
-- 7 Current Active MRR
select sum(mrr)As total_mrr from subscriptions where status_ = "active";
-- 8 Active Accounts Count
select count(distinct account_id) from subscriptions where status_ = "active";
-- 9 Average MRR per Account
SELECT 
  SUM(mrr) * 1.0 / COUNT(DISTINCT account_id) AS avg_mrr_per_active_account
FROM subscriptions
WHERE status_ = 'active';
--  10 mrr segment
SELECT 
    a.segment,
    COUNT(DISTINCT s.account_id) AS Active_account,
    SUM(s.mrr) AS total_mrr
FROM
    subscriptions s
        JOIN
    accounts a ON s.account_id = a.account_id
WHERE
    s.status_ = 'active'
GROUP BY a.segment
ORDER BY total_mrr DESC;
-- 11 mrr by region 
select a.region,sum(s.mrr) as total_mrr from subscriptions s join accounts a on s.account_id = a.account_id where s.status_ ="active" group by a.region order by total_mrr desc;
--  12 MRR by Plan
select plan,sum(mrr) as total_mrr, count(distinct account_id) As accounts from subscriptions where status_ = "active" group by plan order by total_mrr desc;
--  13 historical cancellation rate
select count(distinct case when status_ = "canceled" then account_id end) * 1.0 / count(distinct account_id) As historical_churn from subscriptions;
-- 14 revenue churn(historical)
select sum(case when status_ = "canceled" then mrr end) * 1.0 / sum(mrr) As revenue_churn from subscriptions;
-- 15 Churn by segment
SELECT 
a.segment,
COUNT(*) AS churned_accounts
FROM accounts a
WHERE NOT EXISTS (
    SELECT 1
    FROM subscriptions s
    WHERE s.account_id = a.account_id
      AND s.status_ = 'active'
)
GROUP BY a.segment;
-- 16 current churn
SELECT 
COUNT(*) * 1.0 /
(SELECT COUNT(*) FROM accounts)
AS true_logo_churn
FROM accounts a
WHERE NOT EXISTS (
    SELECT 1
    FROM subscriptions s
    WHERE s.account_id = a.account_id
      AND s.status_ = 'active'
);
-- 17 Detect Movement (Upgrade / Downgrade)
WITH subscription_changes AS (
    SELECT 
        account_id,
        started_at,
        mrr,
        LAG(mrr) OVER (
            PARTITION BY account_id
            ORDER BY started_at
        ) AS previous_mrr
    FROM subscriptions
)

SELECT 
    account_id,
    started_at,
    mrr,
    previous_mrr,
    (mrr - previous_mrr) AS mrr_change,
    CASE 
        WHEN previous_mrr IS NULL THEN 'New'
        WHEN mrr > previous_mrr THEN 'Upgrade'
        WHEN mrr < previous_mrr THEN 'Downgrade'
        ELSE 'No Change'
    END AS movement_type
FROM subscription_changes
ORDER BY account_id, started_at;

WITH subscription_changes AS (
    SELECT 
        account_id,
        started_at,
        mrr,
        LAG(mrr) OVER (
            PARTITION BY account_id
            ORDER BY started_at
        ) AS previous_mrr
    FROM subscriptions
)
SELECT 
    SUM(CASE WHEN mrr > previous_mrr THEN 1 ELSE 0 END) AS upgrade_count,
    SUM(CASE WHEN mrr < previous_mrr THEN 1 ELSE 0 END) AS downgrade_count
FROM subscription_changes;
-- Which segment is driving upgrades?
WITH subscription_changes AS (
    SELECT 
        s.account_id,
        a.segment,
        s.started_at,
        s.mrr,
        LAG(s.mrr) OVER (
            PARTITION BY s.account_id
            ORDER BY s.started_at
        ) AS previous_mrr
    FROM subscriptions s
    JOIN accounts a 
        ON s.account_id = a.account_id
)

SELECT 
    segment,
    COUNT(*) AS upgrade_count,
    SUM(mrr - previous_mrr) AS expansion_mrr
FROM subscription_changes
WHERE previous_mrr IS NOT NULL
  AND mrr > previous_mrr
GROUP BY segment
ORDER BY expansion_mrr DESC;
-- Monthly Active Users 
SELECT 
    DATE_FORMAT(occurred_at, '%Y-%m') AS month,
    COUNT(DISTINCT user_id) AS monthly_active_user
FROM events
GROUP BY DATE_FORMAT(occurred_at, '%Y-%m')
ORDER BY month;
-- Events per Account
select u.account_id ,count(e.event_id) as total_events from users u left join events e on u.user_id = e.user_id group by u.account_id;
-- Feature Adoption Rate
SELECT 
feature_name,
COUNT(DISTINCT user_id) * 1.0
/
(SELECT COUNT(DISTINCT user_id) FROM users) AS adoption_rate
FROM events
GROUP BY feature_name
ORDER BY adoption_rate DESC;
-- Engagement Score per Account
select a.account_id,COUNT(DISTINCT u.user_id) AS total_users,
COUNT(DISTINCT e.user_id) AS active_users,
COUNT(e.event_id) AS total_events,
COUNT(DISTINCT e.feature_name) AS features_used
FROM accounts a
LEFT JOIN users u ON a.account_id = u.account_id
LEFT JOIN events e ON u.user_id = e.user_id
GROUP BY a.account_id
-- Account Cohort
select date_format(created_at, "%Y-%M") as cohort_month, count(account_id) as account_created from accounts group by date_format(created_at, "%Y-%M") order by cohort_month ;
-- Subscription Cohort Reven 
select date_format(started_at, "%Y-%M") as subscription_month, sum(mrr) as new_mrr from subscriptions group by date_format(started_at, "%Y-%M") order by subscription_month ;
-- Revenue Share per Account
SELECT 
account_id,
mrr,
mrr * 100.0 / (SELECT SUM(mrr) FROM subscriptions WHERE status_='active') AS revenue_share_pct
FROM subscriptions
WHERE status_='active'
ORDER BY mrr DESC;
-- Top 10 Revenue Accounts
SELECT *
FROM subscriptions
WHERE status_='active'
ORDER BY mrr DESC
LIMIT 10;
-- high risk account 
SELECT 
    a.account_id,
    SUM(s.mrr) AS total_mrr,
    COUNT(e.event_id) AS total_events
FROM accounts a
JOIN subscriptions s 
    ON a.account_id = s.account_id
LEFT JOIN users u 
    ON a.account_id = u.account_id
LEFT JOIN events e 
    ON u.user_id = e.user_id
WHERE s.status_ = 'active'
GROUP BY a.account_id
HAVING 
    total_mrr > (
        SELECT AVG(mrr) 
        FROM subscriptions 
        WHERE status_ = 'active'
    )
    AND total_events < (
        SELECT AVG(event_count)
        FROM (
            SELECT COUNT(e2.event_id) AS event_count
            FROM users u2
            LEFT JOIN events e2 
                ON u2.user_id = e2.user_id
            GROUP BY u2.account_id
        ) t
    );
    
   -- revenue at risk
   SELECT 
    SUM(total_mrr) AS revenue_at_risk
FROM (
    SELECT 
        a.account_id,
        SUM(s.mrr) AS total_mrr,
        COUNT(e.event_id) AS total_events
    FROM accounts a
    JOIN subscriptions s 
        ON a.account_id = s.account_id
    LEFT JOIN users u 
        ON a.account_id = u.account_id
    LEFT JOIN events e 
        ON u.user_id = e.user_id
    WHERE s.status_ = 'active'
    GROUP BY a.account_id
    HAVING 
        total_mrr > (
            SELECT AVG(mrr) 
            FROM subscriptions 
            WHERE status_ = 'active'
        )
        AND total_events < (
            SELECT AVG(event_count)
            FROM (
                SELECT COUNT(e2.event_id) AS event_count
                FROM users u2
                LEFT JOIN events e2 
                    ON u2.user_id = e2.user_id
                GROUP BY u2.account_id
            ) t
        )
) risk;
-- creating table 
SELECT 
    a.account_id,
    a.segment,
    s.mrr,
    COALESCE(e.total_events, 0) AS total_events
FROM accounts a
JOIN subscriptions s 
    ON a.account_id = s.account_id
LEFT JOIN (
    SELECT 
        u.account_id,
        COUNT(ev.event_id) AS total_events
    FROM users u
    LEFT JOIN events ev 
        ON u.user_id = ev.user_id
    GROUP BY u.account_id
) e 
    ON a.account_id = e.account_id
WHERE s.status_ = 'active'
AND s.mrr > 0;

-- revenue at risk
WITH revenue AS (
    SELECT 
        account_id,
        SUM(mrr) AS total_mrr
    FROM subscriptions
    WHERE status_ = 'active'
    GROUP BY account_id
),

engagement AS (
    SELECT 
        u.account_id,
        COUNT(e.event_id) AS total_events,
        MAX(e.occurred_at) AS last_activity
    FROM users u
    LEFT JOIN events e 
        ON u.user_id = e.user_id
    GROUP BY u.account_id
),

combined AS (
    SELECT 
        r.account_id,
        r.total_mrr,
        COALESCE(e.total_events, 0) AS total_events,
        e.last_activity
    FROM revenue r
    LEFT JOIN engagement e 
        ON r.account_id = e.account_id
),

avg_values AS (
    SELECT 
        AVG(total_mrr) AS avg_mrr,
        AVG(total_events) AS avg_events
    FROM combined
),

final AS (
    SELECT 
        c.account_id,
        c.total_mrr,
        c.total_events,
        c.last_activity,
        CASE 
            WHEN c.total_mrr > a.avg_mrr 
                 AND c.total_events < a.avg_events
                 AND DATEDIFF(CURDATE(), c.last_activity) > 30
            THEN 'High Risk'
            ELSE 'Other'
        END AS account_segment
    FROM combined c
    CROSS JOIN avg_values a
)

SELECT 
    COUNT(*) AS high_risk_accounts,
    ROUND(SUM(total_mrr), 2) AS revenue_at_risk
FROM final
WHERE account_segment = 'High Risk';
-- account summary
SELECT 
    r.account_id,
    r.total_mrr,
    IFNULL(e.total_events, 0) AS total_events,
    e.last_activity,

    CASE 
        WHEN r.total_mrr > avg_vals.avg_mrr
             AND IFNULL(e.total_events, 0) < avg_vals.avg_events
             AND DATEDIFF(CURDATE(), e.last_activity) > 30
        THEN 'High Risk'
        ELSE 'Other'
    END AS account_segment

FROM 
    (
        -- Revenue per account
        SELECT 
            account_id,
            SUM(mrr) AS total_mrr
        FROM subscriptions
        WHERE status_ = 'active'
        GROUP BY account_id
    ) r

LEFT JOIN 
    (
        -- Engagement per account
        SELECT 
            u.account_id,
            COUNT(e.event_id) AS total_events,
            MAX(e.occurred_at) AS last_activity
        FROM users u
        LEFT JOIN events e 
            ON u.user_id = e.user_id
        GROUP BY u.account_id
    ) e
ON r.account_id = e.account_id

CROSS JOIN 
    (
        -- Averages
        SELECT 
            AVG(total_mrr) AS avg_mrr,
            AVG(total_events) AS avg_events
        FROM (
            SELECT 
                r2.account_id,
                r2.total_mrr,
                IFNULL(e2.total_events, 0) AS total_events
            FROM 
                (
                    SELECT account_id, SUM(mrr) AS total_mrr
                    FROM subscriptions
                    WHERE status_ = 'active'
                    GROUP BY account_id
                ) r2
            LEFT JOIN 
                (
                    SELECT 
                        u2.account_id,
                        COUNT(e2.event_id) AS total_events
                    FROM users u2
                    LEFT JOIN events e2 
                        ON u2.user_id = e2.user_id
                    GROUP BY u2.account_id
                ) e2
            ON r2.account_id = e2.account_id
        ) base
    ) avg_vals

ORDER BY r.total_mrr DESC;