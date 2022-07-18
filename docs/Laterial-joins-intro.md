## Laterial joins more like a correlated subquery

There is an interesting stackover flow question [What is the difference between LATERAL JOIN and a subquery in PostgreSQL?](https://stackoverflow.com/questions/28550679/what-is-the-difference-between-lateral-join-and-a-subquery-in-postgresql) and a couple of key comments here 
> Subqueries appearing in FROM can be preceded by the key word LATERAL. This allows them to reference columns provided by preceding FROM items. (Without LATERAL, each subquery is evaluated independently and so cannot cross-reference any other FROM item.)

and
> A LATERAL join is more like a correlated subquery, not a plain subquery, in that expressions to the right of a LATERAL join are evaluated once for each row left of it - just like a correlated subquery - while a plain subquery (table expression) is evaluated once only. (The query planner has ways to optimize performance for either, though.)


The cybertec blog post (thanks to Hans-Jürgen Schönig) details below
* is an easy example to follow 
* there are no indexes which is fine for a small demo, but it would be interesting to see if there are any optimizer gotcha's
* I've included a few sample execution plans for the initial demo query and then for a x10 and x100 sized wishlist



## Details

Setup exactly as per blog post [understanding-lateral-joins-in-postgresql](https://www.cybertec-postgresql.com/en/understanding-lateral-joins-in-postgresql)
```
CREATE TABLE t_product AS
    SELECT   id AS product_id,
             id * 10 * random() AS price,
             'product ' || id AS product
    FROM generate_series(1, 1000) AS id;
 
CREATE TABLE t_wishlist
(
    wishlist_id        int,
    username           text,
    desired_price      numeric
);
 
INSERT INTO t_wishlist VALUES
    (1, 'hans', '450'),
    (2, 'joe', '60'),
    (3, 'jane', '1500')
;
```

and rerunning Hans-Jürgen Schönig tests

```
dave=# SELECT * FROM t_product LIMIT 10;
 product_id |       price        |  product   
------------+--------------------+------------
          1 | 7.0911057104191855 | product 1
          2 |  7.019574865519402 | product 2
          3 | 18.389889881335293 | product 3
          4 | 29.439922787463075 | product 4
          5 | 12.225321030381764 | product 5
          6 |  42.66673675460005 | product 6
          7 |  22.36817195661935 | product 7
          8 |  17.24661160976467 | product 8
          9 |  83.28697235355094 | product 9
         10 |  80.69135379899244 | product 10
(10 rows)

dave=# SELECT        *
FROM      t_wishlist AS w,
    LATERAL  (SELECT      *
        FROM       t_product AS p
        WHERE       p.price < w.desired_price
        ORDER BY p.price DESC
        LIMIT 3
       ) AS x
ORDER BY wishlist_id, price DESC;
 wishlist_id | username | desired_price | product_id |       price        |   product   
-------------+----------+---------------+------------+--------------------+-------------
           1 | hans     |           450 |         84 | 449.81633314892076 | product 84
           1 | hans     |           450 |        493 | 449.64680384533335 | product 493
           1 | hans     |           450 |         60 |  442.2167425320872 | product 60
           2 | joe      |            60 |        875 |  59.57809603155617 | product 875
           2 | joe      |            60 |        379 | 58.199987839874936 | product 379
           2 | joe      |            60 |        196 | 54.127530620999806 | product 196
           3 | jane     |          1500 |        918 | 1499.7965996733715 | product 918
           3 | jane     |          1500 |        464 | 1496.0035338700145 | product 464
           3 | jane     |          1500 |        830 | 1484.0523118239605 | product 830
(9 rows)
```

next looking at the explain plan

```
dave=# explain (analyze,buffers) SELECT        *
FROM      t_wishlist AS w,
    LATERAL  (SELECT      *
        FROM       t_product AS p
        WHERE       p.price < w.desired_price
        ORDER BY p.price DESC
        LIMIT 3
       ) AS x
ORDER BY wishlist_id, price DESC;
                                                            QUERY PLAN                                                             
-----------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=23428.53..23434.90 rows=2550 width=91) (actual time=1.372..1.375 rows=9 loops=1)
   Sort Key: w.wishlist_id, p.price DESC
   Sort Method: quicksort  Memory: 25kB
   Buffers: shared hit=25
   ->  Nested Loop  (cost=27.30..23284.24 rows=2550 width=91) (actual time=0.369..1.336 rows=9 loops=1)
         Buffers: shared hit=25
         ->  Seq Scan on t_wishlist w  (cost=0.00..18.50 rows=850 width=68) (actual time=0.018..0.020 rows=3 loops=1)
               Buffers: shared hit=1
         ->  Limit  (cost=27.30..27.31 rows=3 width=23) (actual time=0.433..0.434 rows=3 loops=3)
               Buffers: shared hit=24
               ->  Sort  (cost=27.30..28.14 rows=333 width=23) (actual time=0.431..0.431 rows=3 loops=3)
                     Sort Key: p.price DESC
                     Sort Method: top-N heapsort  Memory: 25kB
                     Buffers: shared hit=24
                     ->  Seq Scan on t_product p  (cost=0.00..23.00 rows=333 width=23) (actual time=0.008..0.383 rows=224 loops=3)
                           Filter: (price < (w.desired_price)::double precision)
                           Rows Removed by Filter: 776
                           Buffers: shared hit=24
 Planning:
   Buffers: shared hit=13
 Planning Time: 0.514 ms
 Execution Time: 1.440 ms
(22 rows)
```
and again using a x10 bigger wishlist
```
dave=# explain (analyze,buffers) SELECT        *
FROM      t_wishlist AS w,
    LATERAL  (SELECT      *
        FROM       t_product AS p
        WHERE       p.price < w.desired_price
        ORDER BY p.price DESC
        LIMIT 30
       ) AS x
ORDER BY wishlist_id, price DESC;
                                                            QUERY PLAN                                                             
-----------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=30368.35..30432.10 rows=25500 width=91) (actual time=2.634..2.644 rows=90 loops=1)
   Sort Key: w.wishlist_id, p.price DESC
   Sort Method: quicksort  Memory: 32kB
   Buffers: shared hit=25
   ->  Nested Loop  (cost=32.83..28501.98 rows=25500 width=91) (actual time=0.934..1.661 rows=90 loops=1)
         Buffers: shared hit=25
         ->  Seq Scan on t_wishlist w  (cost=0.00..18.50 rows=850 width=68) (actual time=0.044..0.045 rows=3 loops=1)
               Buffers: shared hit=1
         ->  Limit  (cost=32.83..32.91 rows=30 width=23) (actual time=0.522..0.529 rows=30 loops=3)
               Buffers: shared hit=24
               ->  Sort  (cost=32.83..33.67 rows=333 width=23) (actual time=0.520..0.523 rows=30 loops=3)
                     Sort Key: p.price DESC
                     Sort Method: top-N heapsort  Memory: 29kB
                     Buffers: shared hit=24
                     ->  Seq Scan on t_product p  (cost=0.00..23.00 rows=333 width=23) (actual time=0.169..0.457 rows=224 loops=3)
                           Filter: (price < (w.desired_price)::double precision)
                           Rows Removed by Filter: 776
                           Buffers: shared hit=24
 Planning Time: 4.372 ms
 Execution Time: 3.216 ms
(20 rows)
```
and finally again using a x100 bigger wishlist
```
dave=# explain (analyze,buffers) SELECT        *
FROM      t_wishlist AS w,
    LATERAL  (SELECT      *
        FROM       t_product AS p
        WHERE       p.price < w.desired_price
        ORDER BY p.price DESC
        LIMIT 300
       ) AS x
ORDER BY wishlist_id, price DESC;
                                                            QUERY PLAN                                                             
-----------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=73140.09..73777.59 rows=255000 width=91) (actual time=2.216..2.278 rows=545 loops=1)
   Sort Key: w.wishlist_id, p.price DESC
   Sort Method: quicksort  Memory: 67kB
   Buffers: shared hit=25
   ->  Nested Loop  (cost=36.95..37164.92 rows=255000 width=91) (actual time=0.624..1.859 rows=545 loops=1)
         Buffers: shared hit=25
         ->  Seq Scan on t_wishlist w  (cost=0.00..18.50 rows=850 width=68) (actual time=0.019..0.020 rows=3 loops=1)
               Buffers: shared hit=1
         ->  Limit  (cost=36.95..37.70 rows=300 width=23) (actual time=0.493..0.556 rows=182 loops=3)
               Buffers: shared hit=24
               ->  Sort  (cost=36.95..37.78 rows=333 width=23) (actual time=0.491..0.515 rows=182 loops=3)
                     Sort Key: p.price DESC
                     Sort Method: quicksort  Memory: 58kB
                     Buffers: shared hit=24
                     ->  Seq Scan on t_product p  (cost=0.00..23.00 rows=333 width=23) (actual time=0.013..0.404 rows=224 loops=3)
                           Filter: (price < (w.desired_price)::double precision)
                           Rows Removed by Filter: 776
                           Buffers: shared hit=24
 Planning Time: 7.793 ms
 Execution Time: 2.387 ms
(20 rows)
```