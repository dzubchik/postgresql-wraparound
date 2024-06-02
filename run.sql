\set id random(1, 100000)
UPDATE pgbench_accounts SET abalance = abalance + 1 WHERE aid = :id;