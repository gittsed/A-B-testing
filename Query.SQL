/*Query for extraction and cleaning the null data from the database.*/

SELECT uu.id,
       COALESCE(uu.country,'unknown') AS country,
       COALESCE(uu.gender,'unknown') AS gender,
       COALESCE(aa.device,'unknown') AS device,
       COALESCE(gg.group,'unknown') AS test_group,
       CASE WHEN SUM(aa.spent)>0 THEN '1'
       ELSE '0'
       END AS conversions,
       COALESCE(SUM(aa.spent),0) AS spent_per_user
FROM users uu
     LEFT JOIN activity aa ON uu.id=aa.uid
     LEFT JOIN groups gg ON uu.id=gg.uid
GROUP BY uu.id,aa.device,gg.group

/* To find the conversion rate for all users*/

WITH table1 AS(
SELECT uid,
       CASE WHEN SUM(spent)>0 THEN '1'
       ELSE '0'
       END as conversion_u
FROM activity 
GROUP BY uid),
table2 AS(
SELECT COUNT(DISTINCT table1.uid) as users_converted
from  table1
WHERE conversion_u='1'),
table3 AS
(SELECT CAST (COUNT(DISTINCT uu.id) as FLOAT) as tot_user
from users uu
          )
SELECT users_converted/tot_user AS conversion_rate
FROM table2
CROSS JOIN table3

/*To find conversion rate for control and treatment group*/

WITH table1 AS(SELECT uid,CASE WHEN SUM(spent)>0 THEN '1' ELSE '0' END as conversion_u
FROM activity 
GROUP BY uid),
table2 AS(SELECT COUNT(DISTINCT gg.uid) as tot_users_control
from  groups gg
WHERE  gg.group='A'),
table3 AS(SELECT COUNT(DISTINCT gg.uid) as tot_users_treatment
from  groups gg
WHERE  gg.group='B'),
table4 AS(SELECT CAST(COUNT(DISTINCT table1.uid) AS FLOAT) as users_control_converted
from  table1
INNER JOIN groups gg
USING(uid)
WHERE conversion_u='1' AND gg.group='A'),
table5 AS(SELECT CAST(COUNT(DISTINCT table1.uid) AS FLOAT) as users_treatment_converted
from  table1
INNER JOIN groups gg
USING(uid)
WHERE conversion_u='1'AND gg.group='B')
SELECT users_control_converted/tot_users_control AS control_conversion_rate,users_treatment_converted/tot_users_treatment AS treatment_conversion_rate
FROM table4
CROSS JOIN table2 CROSS JOIN table5 CROSS JOIN table3



/*To find average spent per test group*/

WITH table1 AS(SELECT uid,COALESCE(SUM(spent),0) as control_spent_per_user
FROM groups gg
LEFT JOIN activity
USING(uid)
WHERE gg.group='A'
GROUP BY uid),
table2 AS(SELECT uid,COALESCE(SUM(spent),0) as treatment_spent_per_user
FROM groups gg
LEFT JOIN activity
USING(uid)
WHERE gg.group='B'
GROUP BY uid),
table3 AS(SELECT SUM(control_spent_per_user)/COUNT (distinct(table1.uid)) AS average_spent_for_control
from table1),
table4 AS(
SELECT SUM(treatment_spent_per_user)/COUNT (distinct(uid)) AS average_spent_for_treatment
FROM table2)
SELECT average_spent_for_control,average_spent_for_treatment
FROM table3
CROSS JOIN table4

/* To find include date columns for novelty effect analysis*/


SELECT uu.id,
       COALESCE(uu.country,'unknown') AS country,
       COALESCE(uu.gender,'unknown') AS gender,
       COALESCE(aa.device,'unknown') AS device,
       COALESCE(gg.group,'unknown') AS test_group,
       aa.dt,
       gg.join_dt,
       CASE WHEN SUM(aa.spent)>0 THEN '1'
       ELSE '0'
       END AS conversions,
       COALESCE(SUM(aa.spent),0) AS spent_per_user
FROM users uu
LEFT JOIN activity aa
ON uu.id=aa.uid
LEFT JOIN groups gg
ON uu.id=gg.uid
GROUP BY uu.id,aa.device,gg.group,aa.dt,gg.join_dt
