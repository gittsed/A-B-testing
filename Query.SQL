/*a SQL query that returns: the user ID, the user’s country,
the user’s gender, the user’s device type, the user’s test group, 
whether or not they converted (spent > $0), and how much they spent in total ($0+).*/

SELECT uu.id,
       COALESCE(uu.country,'unknown') AS country,
       COALESCE(uu.gender,'unknown') AS gender,
       COALESCE(gg.device,'unknown') AS device,
       COALESCE(gg.group,'unknown') AS test_group,
       CASE WHEN SUM(aa.spent)>0 THEN '1'
            ELSE '0'
       END AS conversions,
       COALESCE(SUM(aa.spent),0) AS spent_per_user
FROM users uu
     LEFT JOIN groups gg ON uu.id=gg.uid
     LEFT JOIN activity aa ON uu.id=aa.uid
GROUP BY uu.id,
         uu.country,
         uu.gender,
         aa.device,
         gg.group

--Understanding the database
/*Can a user show up more than once in the activity table? Yes or no, and why?
YES, a user might purchase more than once and it will be recorded in to a new row in the activity table.
We can make this sure using the below query. */

SELECT aa.uid,
       COUNT(*) purchase_peruser
FROM activity aa
GROUP BY aa.uid
HAVING COUNT(*) >1

/*What type of join should we use to join the users table to the activity table?
LEFT JOIN, we will need all users including that don't purchase anything.
It is important to calculate the revenue, average spent per user and conversion rate.
*/

SELECT uu.id,
       uu.country,
       uu.gender,
       aa.device,
       gg.group,
       CASE WHEN SUM(aa.spent)>0 THEN '1'
       ELSE '0'
       END AS conversions,
       COALESCE(SUM(aa.spent),0) AS spent_per_user
FROM users uu
     LEFT JOIN activity aa ON uu.id=aa.uid
     LEFT JOIN groups gg ON uu.id=gg.uid
GROUP BY uu.id,
         aa.device,
         gg.group
--The LEFT JOIN returns 48943 records of result set

SELECT uu.id,
       uu.country,
       uu.gender,
       aa.device,
       gg.group,
       CASE WHEN SUM(aa.spent)>0 THEN '1'
       ELSE '0'
       END AS conversions,
       COALESCE(SUM(aa.spent),0) AS spent_per_user
FROM users uu
     LEFT JOIN activity aa ON uu.id=aa.uid
     LEFT JOIN groups gg ON uu.id=gg.uid
GROUP BY uu.id,
         aa.device,
         gg.group
--INNER JOIN returns 2094 records in the result set.

--What SQL function can we use to fill in NULL values?
--ANS coalesc function. Syntax: COALESC(column_name,'put what you want to see instead of the null')

--What are the start and end dates of the experiment?

SELECT MAX(gg.join_dt),
       MIN(gg.join_dt)
FROM groups gg

--How many total users were in the experiment? id is the primary key so we dont need to use distinct.

SELECT COUNT(uu.id)
FROM users uu

--How many users were in the control and treatment groups?

SELECT gg.group,
       COUNT(uu.id)
FROM users uu
     LEFT JOIN groups gg ON uu.id=gg.uid
GROUP BY gg.group

--What was the conversion rate of all users

WITH status AS(
SELECT uid,
       CASE WHEN SUM(spent)>0 THEN '1'
            ELSE '0'
       END as conversion_status
FROM activity 
GROUP BY uid),
converted_user AS (SELECT COUNT(DISTINCT status.uid) as users_converted
FROM  status
WHERE conversion_status='1'),
total_user AS (SELECT CAST (COUNT(DISTINCT uu.id) as FLOAT) as tot_user
FROM users uu)
SELECT users_converted/tot_user AS conversion_rate
FROM converted_user
CROSS JOIN total_user

--What is the user conversion rate for the control and treatment groups?
WITH status AS(
 SELECT uid,
        CASE WHEN SUM(spent)>0 THEN '1'
             ELSE '0'
        END as conversion_status
  FROM activity 
  GROUP BY uid),
control_users AS (
  SELECT COUNT(DISTINCT gg.uid) as tot_users_control
  FROM  groups gg
  WHERE  gg.group='A'),
treatment_users AS (
  SELECT COUNT(DISTINCT gg.uid) as tot_users_treatment
  FROM  groups gg
  WHERE  gg.group='B'),
control_converted AS(
  SELECT CAST(COUNT(DISTINCT status.uid) AS FLOAT) as users_control_converted
  FROM  status
  INNER JOIN groups gg
  USING(uid)
  WHERE conversion_status='1' AND gg.group='A'),
treatment_converted AS(
  SELECT CAST(COUNT(DISTINCT status.uid) AS FLOAT) as users_treatment_converted
  FROM status
  INNER JOIN groups gg USING(uid)
  WHERE conversion_status='1'AND gg.group='B')
SELECT users_control_converted/tot_users_control AS control_conversion_rate,
       users_treatment_converted/tot_users_treatment AS treatment_conversion_rate
FROM control_converted
     CROSS JOIN control_users
     CROSS JOIN treatment_converted
     CROSS JOIN treatment_users

/*What is the average amount spent per user for the control and treatment groups, 
including users who did not convert*/

WITH control_spent_peruser AS(
  SELECT uid,
         COALESCE(SUM(spent),0) as control_spent_per_user
  FROM groups gg
       LEFT JOIN activity USING(uid)
  WHERE gg.group='A'
  GROUP BY uid),
treatment_spent_peruser AS(
  SELECT uid,
         COALESCE(SUM(spent),0) as treatment_spent_per_user
  FROM groups gg
       LEFT JOIN activity USING(uid)
  WHERE gg.group='B'
  GROUP BY uid),
control_average AS(
  SELECT SUM(control_spent_per_user)/COUNT (distinct(uid)) AS average_spent_for_control
  FROM control_spent_peruser),
treatment_average AS(
  SELECT SUM(treatment_spent_per_user)/COUNT (distinct(uid)) AS average_spent_for_treatment
  FROM treatment_spent_peruser)
SELECT average_spent_for_control,
       average_spent_for_treatment
FROM control_average
     CROSS JOIN treatment_average

/*Why does it matter to include users who did not convert when calculating the average amount spent per user?
ANS- when analyzing companies profit two things matter. 
First how many customer did the purchase? and how much they spent?
This is crucial to differentiate if the experiment results in more customers converted and spent less
or less customers converted and spent high to assess the tradeoff.*/

