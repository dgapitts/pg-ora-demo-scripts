## psql-os-host-commands

this is useful i.e. I want to quickly review a script while connected to my benchdb in psql

```
benchdb=> \!cat create-table-big_insert_test.sql
invalid command \!cat
Try \? for help.
benchdb=> \! cat create-table-big_insert_test.sql
create table big_insert_test2(f1 varchar,f2 varchar);
```

or even simpler

```
postgres=> \!date
invalid command \!date
Try \? for help.
postgres=> \! date
Fri Jun  9 10:52:20 UTC 2023
```

the key thing to remember is 
* that you need a *space* between the `\?` and the `command`
* more details (if required) in [this blog post](https://joshuaotwell.com/shell-excitement-with-the-psql-meta-command/)

