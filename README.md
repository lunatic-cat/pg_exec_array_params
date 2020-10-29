# PgExecArrayParams

![](https://github.com/lunatic-cat/pg_exec_array_params/workflows/ci/badge.svg)

## Usage

```ruby
# `params` CAN include primitive homogeneous arrays: [[1, 2]]
PgExecArrayParams.exec_array_params(conn, sql, params)
```

## Problem

```ruby
pg_connection.exec_params('select * from users where id = $1', [1,2])
PG::IndeterminateDatatype: ERROR:  could not determine data type of parameter $2

pg_connection.exec_params('select * from users where id = $1', [[1,2]])
PG::InvalidTextRepresentation: ERROR:  invalid input syntax for integer: "[1, 2]"
```

## Solution

```ruby
# rewrite query under the hood to
# select * from users where id IN ($1, $2)
PgExecArrayParams.exec_array_params(conn, 'select * from users where id = $1', [[1,2]])
=> [{"id" => 1}, {"id" => 2}]
```

## Integration with 'pg' gem

```ruby
PG::Connection.include(PgExecArrayParams) # once in initializer

conn.pg_exec_array_params('select * from users where id = $1', [[1,2]])
=> [{"id" => 1}, {"id" => 2}]
```