# PgExecArrayParams

![](https://github.com/lunatic-cat/pg_exec_array_params/workflows/ci/badge.svg)

## Problem

```ruby
pg_connection.exec_params('select * from users where id in ($1)', [1,2])
PG::IndeterminateDatatype: ERROR:  could not determine data type of parameter $2

pg_connection.exec_params('select * from users where id in ($1)', [[1,2]])
PG::InvalidTextRepresentation: ERROR:  invalid input syntax for integer: "[1, 2]"
```
