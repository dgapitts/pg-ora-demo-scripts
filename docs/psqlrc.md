## Customize psql with ~/.psqlrc - add useful alias commands with tab completion


I recently add [psqlrc commands based off https://github.com/datachomp/dotfiles/blob/master/.psqlrc](https://github.com/dgapitts/vagrant-c7-pg13-pg13/commit/a59ce47941f5ba8d364227c1097d1cffbe5254f8)

I want to give a quick demo of how this works

Starting off with a simple example

```
-bash-4.2$ grep 'set sp' .psqlrc
\set sp 'SHOW search_path;'
```

and from psql
```
[local] postgres@postgres=# :sp
┌─────────────────┐
│   search_path   │
├─────────────────┤
│ "$user", public │
└─────────────────┘
(1 row)

Time: 0.172 ms
```

note the prompt is customized

```
-bash-4.2$ grep 'set PROMPT1'  ~/.psqlrc
--\set PROMPT1 '%[%033[33;1m%]%x%[%033[0m%]%[%033[1m%]%/%[%033[0m%]%R%# '
\set PROMPT1 '%[%033[1m%]%M %n@%/%R%[%033[0m%]%# '
--\set PROMPT1 '%[%033[1m%]%M/%/%R%[%033[0m%]%# '
```

there is also tab-completion
```
[local] postgres@postgres=# :t
:tablesize         :total_index_size  :trashindexes      :tsize	
```

i.e. matching the follow 4 records starting with a `t`

```
-bash-4.2$ grep 'set t' .psqlrc
\set tablesize 'SELECT nspname || \'.\' || relname AS \"relation\", pg_size_pretty(pg_relation_size(C.oid)) AS "size" FROM pg_class C LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace) WHERE nspname NOT IN (\'pg_catalog\', \'information_schema\') ORDER BY pg_relation_size(C.oid) DESC LIMIT 40;'
\set trashindexes '( select s.schemaname as sch, s.relname as rel, s.indexrelname as idx, s.idx_scan as scans, pg_size_pretty(pg_relation_size(s.relid)) as ts, pg_size_pretty(pg_relation_size(s.indexrelid)) as "is" from pg_stat_user_indexes s join pg_index i on i.indexrelid=s.indexrelid left join pg_constraint c on i.indrelid=c.conrelid and array_to_string(i.indkey, '' '') = array_to_string(c.conkey, '' '') where i.indisunique is false and pg_relation_size(s.relid) > 1000000 and s.idx_scan < 100000 and c.confrelid is null order by s.idx_scan asc, pg_relation_size(s.relid) desc );'
\set tsize '(select table_schema, table_name, pg_size_pretty(size) as size, pg_size_pretty(total_size) as total_size from (:_rtsize) x order by x.size desc, x.total_size desc, table_schema, table_name);'
\set total_index_size 'SELECT pg_size_pretty(sum(relpages*1024)) AS size FROM pg_class WHERE reltype=0;'
```



