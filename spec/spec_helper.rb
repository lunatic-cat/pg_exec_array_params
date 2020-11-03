# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

if ENV['CI'] && ENV['CODECOV_TOKEN']
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require 'bundler/setup'
require 'rspec/its'
require 'pry-byebug'
require 'pg'

require 'pg_exec_array_params'

RSpec.shared_context 'shared sql methods' do
  def connect
    PG.connect(
      host: ENV.fetch('POSTGRES_HOST', '127.0.0.1'),
      dbname: ENV.fetch('POSTGRES_DB'),
      user: ENV['POSTGRES_USER'],
      password: ENV['POSTGRES_PASSWORD']
    )
  end

  def silence(conn)
    conn.exec('SET client_min_messages = warning') # supress NOTICE:  relation "users" already exists, skipping
    yield
  ensure
    conn.exec('SET client_min_messages = notice')
  end
end

RSpec.shared_context 'shared tables' do
  include_context 'shared sql methods'

  let(:min_age) { 10 }
  let(:max_age) { 20 }

  let!(:conn) do
    connect.tap do |conn|
      silence(conn) do
        conn.exec('DROP TABLE IF EXISTS users')
        conn.exec('CREATE TABLE IF NOT EXISTS users (age integer)')
      end
      conn.exec("INSERT INTO users(age) SELECT generate_series(#{min_age}, #{max_age})")
    end
  end

  after do
    conn.close
  end
end

RSpec::Matchers.define :fetch_rows do |expected|
  match do |actual|
    @actual = actual.to_a
    values_match? expected, actual
  end

  diffable
end

module PgQueryParser
  def parse_res_target(sql)
    PgQuery.parse(sql).tree[0]
           .fetch('RawStmt').fetch('stmt')
           .fetch('SelectStmt').fetch('targetList')
           .first.fetch('ResTarget')
  end

  def squish(str)
    str
      .gsub(/\A[[:space:]]+/, '')
      .gsub(/[[:space:]]+\z/, '')
      .gsub(/[[:space:]]+/, ' ')
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    PG::Connection.include(PgExecArrayParams)
  end

  config.include PgExecArrayParams, pg: true
  config.include PgQueryParser
end
