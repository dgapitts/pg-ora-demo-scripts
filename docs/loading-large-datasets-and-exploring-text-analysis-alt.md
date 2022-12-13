## Loading large datasets and exploring text analysis with Ulysses - using a temporary table to hold data and serial for line number

This is alternative to [here - when I added line numbers via `cat -n`](loading-large-datasets-and-exploring-text-analysis.md)  

Setup `ulysses_v2` table version using `serial` (auto incrementing) for line_num
```
dave=# create TABLE ulysses_v2 (line_num serial, line_text varchar);
CREATE TABLE
```
load data into temp table
```
dave=# create temporary table  temp_lines_only (line_text varchar);
CREATE TABLE
dave=# \copy temp_lines_only FROM 'Ulysses-Jame-Joyce-1922.txt'
COPY 33216
```
insert data into permanent table
```
dave=# insert into ulysses_v2 (line_text) select line_text from temp_lines_only;
INSERT 0 33216
```


## Compare results

Interesting the line_num are out by one
```
dave=# select line_num, line_text from ulysses where lower(line_text) like '%amsterdam%';
 line_num |                               line_text
----------+------------------------------------------------------------------------
    21018 | burning part produced Fritz of Amsterdam, the thinking hyena. _(He
    27922 | End_ by Jans Pieter Sweelinck, a Dutchman of Amsterdam where the frows
(2 rows)

dave=# select line_num, line_text from ulysses_v2 where lower(line_text) like '%amsterdam%';
 line_num |                               line_text
----------+------------------------------------------------------------------------
    21027 | burning part produced Fritz of Amsterdam, the thinking hyena. _(He
    27933 | End_ by Jans Pieter Sweelinck, a Dutchman of Amsterdam where the frows
(2 rows)
```

but that is only because I excluded line 15 in the first method
```
dave=# select line_num, line_text from ulysses where line_num between 14 and 16;
 line_num |                 line_text
----------+--------------------------------------------
       14 |
       16 | [Most recently updated: December 27, 2019]
(2 rows)

dave=# select line_num, line_text from ulysses_v2 where line_num between 14 and 16;
 line_num |                   line_text
----------+-----------------------------------------------
       14 |
       15 | Release Date: December 27, 2001 [eBook #4300]
       16 | [Most recently updated: December 27, 2019]
(3 rows)
```
