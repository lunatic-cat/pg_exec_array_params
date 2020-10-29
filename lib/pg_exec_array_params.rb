# frozen_string_literal: true

require 'pg'
require 'pg_exec_array_params/version'

# PgExecArrayParams
module PgExecArrayParams
  class Error < StandardError; end
  module_function

  def exec_array_params(conn, sql, params, *args)
    conn.exec_params(sql, params, *args)
  end
end
