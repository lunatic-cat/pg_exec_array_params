# PgExecArrayParams

![](https://github.com/lunatic-cat/pg_exec_array_params/workflows/ci/badge.svg)

Use same parametized query and put `Array<T>` instead of any `T`

## Example

```ruby
query = 'select * from t1 where a1 = $1 and a2 = $2 and a3 = $3 and a4 = $4'
params = [1, [2, 3], 'foo', ['bar', 'baz']]

# PG::Connection.exec_params called with:
# 'SELECT * FROM "t1" WHERE "a1" = $1 AND "a2" IN ($2, $3) AND "a3" = $4 AND "a4" IN ($5, $6)'
# [1, 2, 3, "foo", "bar", "baz"]
PgExecArrayParams.exec_array_params(conn, query, params)
```

## Problem

```ruby
conn.exec_params('select * from users where id IN ($1)', [1,2])
=> PG::IndeterminateDatatype: ERROR:  could not determine data type of parameter $2

conn.exec_params('select * from users where id IN ($1)', [[1,2]])
=> PG::InvalidTextRepresentation: ERROR:  invalid input syntax for integer: "[1, 2]"
```

Currently you would generate `$n` parts and flatten params.
Or you can inline and embed arrays into query. *Don't forget to escape them*

## Solution

This library encapsulates the first approach in a clean way:

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

## Rails note

`ActiveRecord` uses the second path (inline + escape).

```ruby
User.where(age: ["1'; drop table users;", "2"]).to_sql
=> SELECT "users".* FROM "users" WHERE "users"."age" IN ('1''; drop table users;', '2')
```

It's solid and bulletproof, but

- it must support multiple databases, but non-trivial queries require raw sql chunks anyway
- it's clever, but not so fast as raw `pg`
- if you're using `AR::Relation#to_sql` just to handle arrays, consider using this

## Benchmark

```sh
BENCH_PG_URL='postgres://...' bundle exec ruby benchmark.rb
```

<details>
<summary>Benchmarking SQL generation</summary>

```
Warming up --------------------------------------
        activerecord     1.070k i/100ms
   exec_array_params   213.704k i/100ms
Calculating -------------------------------------
        activerecord     11.359k (± 3.9%) i/s -     56.710k in   5.000406s
   exec_array_params      2.151M (± 3.0%) i/s -     10.899M in   5.072579s
```
</details>

```
Comparison:
   exec_array_params:  2150601.0 i/s
        activerecord:    11359.0 i/s - 189.33x  (± 0.00) slower
```

<details>
<summary>Benchmarking query</summary>

```
Warming up --------------------------------------
   activerecord#to_a     1.000  i/100ms
  activerecord#pluck     1.000  i/100ms
   exec_array_params     2.000  i/100ms
                  pg     2.000  i/100ms
Calculating -------------------------------------
   activerecord#to_a      4.429  (± 0.0%) i/s -     23.000  in   5.203405s
  activerecord#pluck     18.889  (± 5.3%) i/s -     95.000  in   5.044102s
   exec_array_params     25.093  (± 4.0%) i/s -    126.000  in   5.039405s
                  pg     23.632  (± 8.5%) i/s -    118.000  in   5.033961s
```
</details>

```
Comparison:
   exec_array_params:       25.1 i/s
                  pg:       23.6 i/s - same-ish: difference falls within error
  activerecord#pluck:       18.9 i/s - 1.33x  (± 0.00) slower
   activerecord#to_a:        4.4 i/s - 5.67x  (± 0.00) slower
```