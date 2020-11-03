# frozen_string_literal: true

require 'pg_query'

module PgExecArrayParams
  class Query
    attr_reader :query, :args

    def initialize(query, args = [])
      @query = query
      @args = args
    end

    def exec_params(conn, *args)
      conn.exec_params(sql, binds, *args)
    end

    def sql
      should_rebuild? ? (rebuild_query! && @sql) : query
    end

    def binds
      should_rebuild? ? args.flatten(1) : args
    end

    def columns
      @columns || (rebuild_query! && @columns)
    end

    private

    def should_rebuild?
      args.any? do |param|
        param.is_a?(Array) && (param.none? do |item|
          item.respond_to?(:each) && raise(Error, "Param includes not primitive: #{item.inspect}")
        end)
      end
    end

    def tree
      @tree ||= PgQuery.parse(query)
    end

    def rebuild_query!
      @columns ||= []
      tree.send :treewalker!, tree.tree do |_expr, key, value, _location|
        case key
        when 'targetList'
          @columns += value.map do |node|
            Column.from_res_target(node['ResTarget'])
          end.compact
        when 'ResTarget'
          Rewriters::ResTarget.new(value, ref_idx).process
        when 'A_Expr'
          Rewriters::AExpr.new(value, ref_idx).process
        end
      end
      @sql = tree.deparse
      true
    rescue Error => e
      e.query = query
      raise e
    end

    def ref_idx
      @ref_idx ||= SqlRefIndex.new(args)
    end
  end
end
