# frozen_string_literal: true

require 'pg'
require 'pg_query'
require 'pg_exec_array_params/query'
require 'pg_exec_array_params/version'

# PgExecArrayParams
module PgExecArrayParams
  class Error < StandardError; end
  module_function

  def exec_array_params(conn, sql, params, *args)
    query = Query.new(sql, params)
    conn.exec_params(query.sql, query.params, *args)
  end

  def self.included(base)
    base.define_method :pg_exec_array_params do |*args|
      PgExecArrayParams.exec_array_params(self, *args)
    end
  end
end
