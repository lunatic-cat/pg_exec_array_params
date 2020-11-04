# frozen_string_literal: true

require 'pg_exec_array_params/error'
require 'pg_exec_array_params/rewriters'
require 'pg_exec_array_params/rewriters/node'
require 'pg_exec_array_params/rewriters/res_target'
require 'pg_exec_array_params/rewriters/a_expr'
require 'pg_exec_array_params/sql_ref_index'
require 'pg_exec_array_params/column'
require 'pg_exec_array_params/query'
require 'pg_exec_array_params/version'

module PgExecArrayParams
  PARAM_REF = 'ParamRef'
  REXPR = 'rexpr'
  NUMBER = 'number'
  LOCATION = 'location'

  # AExpr['kind']
  EQ_KIND = 0
  IN_KIND = 7

  class Optional; end

  module_function

  def exec_array_params(conn, sql, params, *args)
    Query.new(sql, params).exec_params(conn, *args)
  end

  def self.included(base)
    return unless base.name == 'PG::Connection'

    base.define_method :exec_array_params do |sql, params, *args|
      Query.new(sql, params).exec_params(self, *args)
    end
  end
end
