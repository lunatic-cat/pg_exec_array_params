# frozen_string_literal: true

require 'benchmark/ips'
require 'active_record'
require 'pg'

$LOAD_PATH.unshift(File.expand_path('lib', __dir__))
require 'pg_exec_array_params'

class User < ActiveRecord::Base
end

def connect(url)
  # ActiveRecord::Base.legacy_connection_handling = false
  ActiveRecord::Base.logger = Logger.new(IO::NULL)
  ActiveRecord::Base.configurations = { default_env: { adapter: 'postgresql', url: url, pool: 1 } }
  ActiveRecord::Base.establish_connection
  ActiveRecord::Migration.verbose = false
  ActiveRecord::Schema.define(version: 1) do
    create_table :users, if_not_exists: true do |t|
      t.integer :age
    end
    add_index(:users, :age) unless index_exists?(:users, :age)
  end
  ActiveRecord::Base.connection.raw_connection
end

def sql
  puts 'Benchmarking SQL generation'

  connect(ENV.fetch('BENCH_PG_URL'))
  params = ["1'; drop table users;", '2']
  query = 'select * from users where age = $1'

  Benchmark.ips do |x|
    x.report('activerecord') { User.where(age: params).to_sql }
    x.report('exec_array_params') { PgExecArrayParams::Query.new(query, params).sql }
    x.compare!
  end
end

def query
  puts 'Benchmarking query'

  conn = connect(ENV.fetch('BENCH_PG_URL'))
  PG::Connection.include(PgExecArrayParams)
  if conn.exec('select count(*) from users').first['count'].to_i < 1_000_000
    puts "Seed #{conn.exec('INSERT INTO users (age) SELECT generate_series(1,1500000) % 90;')}"
  end

  query = 'select * from users where age IN ($1, $2, $3)'
  params = [10, 20, 30]
  query2 = 'select * from users where age = $1'
  params2 = [[10, 20, 30]]

  Benchmark.ips do |x|
    x.report('activerecord#to_a') { User.where(age: params).to_a }
    x.report('activerecord#pluck') { User.where(age: params).pluck(:id, :age) }
    x.report('exec_array_params')  { conn.pg_exec_array_params(query2, params2).to_a }
    x.report('pg') { conn.exec_params(query, params).to_a }
    x.compare!
  end
end

if __FILE__ == $PROGRAM_NAME
  if (meth = ARGV.first)
    send meth
  else
    sql && query
  end
end
