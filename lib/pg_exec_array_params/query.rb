# frozen_string_literal: true

require 'pg_query'

module PgExecArrayParams
  class Query
    PARAM_REF = 'ParamRef'
    REXPR = 'rexpr'
    A_EXPR = 'A_Expr'
    KIND = 'kind'
    LOCATION = 'location'
    NUMBER = 'number'

    EQ_KIND = 0
    IN_KIND = 7

    TARGET_LIST = 'targetList'
    RES_TARGET = 'ResTarget'

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

    def rebuild_query!
      each_param_ref do |value|
        # puts({value_before: value}.inspect)
        old_ref_idx = value[REXPR][PARAM_REF][NUMBER] - 1 # one based
        new_ref_idx = ref_idx[old_ref_idx]
        if new_ref_idx.is_a?(Array)
          value[KIND] = IN_KIND
          value[REXPR] = Range.new(*new_ref_idx).map do |param_ref_idx|
            { PARAM_REF => { NUMBER => param_ref_idx } }
          end
        else
          value[REXPR][PARAM_REF][NUMBER] = new_ref_idx
          # nested_refs == 1 unwraps, wrap it back
          value[REXPR] = [value[REXPR]] if value[KIND] == IN_KIND
        end
        # puts({value_after_: value}.inspect)
      end
      @sql = tree.deparse
      true
    end

    def tree
      @tree ||= PgQuery.parse(query)
    end

    def each_param_ref(&block)
      tree.send :treewalker!, tree.tree do |_expr, key, value, _location|
        case key
        when TARGET_LIST
          handle_target_list_node(value)
        when A_EXPR
          handle_target_aexpr_node(value, &block)
        end
      end
    end

    def handle_target_aexpr_node(value, &block)
      if assign_param_via_eq?(value)
        block.call(value)
      elsif (nested_refs = assign_param_via_in?(value))
        if nested_refs == 1
          value[REXPR] = value[REXPR].first
          block.call(value)
        else
          message = [
            'Cannot splice multiple references, leave the only one:',
            query,
            refs_underline(value)
          ].join("\n")
          raise Error, message
        end
      end
    end

    def handle_target_list_node(value)
      @columns ||= []
      @columns += value.map { |node| Column.from_res_target(node[RES_TARGET]) }.compact
    end

    def ref_idx
      @ref_idx ||= SqlRefIndex.new(args)
    end

    def refs_underline(value)
      from, size = refs_at(value)
      "#{'^'.rjust(from, ' ')}#{'-'.rjust(size, '-')}^"
    end

    def refs_at(value)
      first_ref = value[REXPR].find { |vexpr| vexpr.key?(PARAM_REF) } [PARAM_REF]
      last_ref = value[REXPR].reverse.find { |vexpr| vexpr.key?(PARAM_REF) } [PARAM_REF]
      started = first_ref[LOCATION] + 1
      ended = last_ref[LOCATION] + last_ref[NUMBER].to_s.size
      [started, ended - started]
    end

    # = $1
    # {"kind"=>0, "name"=>[{"String"=>{"str"=>"="}}],
    #  "lexpr"=>{"ColumnRef"=>{"fields"=>[{"String"=>{"str"=>"companies"}}, {"String"=>{"str"=>"id"}}],
    #                          "location"=>1242}},
    #  "rexpr"=>{"ParamRef"=>{"number"=>4, "location"=>1261}}, "location"=>1259}
    def assign_param_via_eq?(value)
      (value[KIND] == EQ_KIND) && value[REXPR].is_a?(Hash) && value[REXPR].key?(PARAM_REF)
    end

    # IN ($1), returns number of nested REFs
    def assign_param_via_in?(value)
      (value[KIND] == IN_KIND) && value[REXPR].is_a?(Array) && value[REXPR].count { |vexpr| vexpr.key?(PARAM_REF) }
    end
  end
end
