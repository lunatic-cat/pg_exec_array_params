# frozen_string_literal: true

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

    attr_reader :query, :args

    def initialize(query, args = [])
      @query = query
      @args = args
    end

    def exec_params(conn, *args)
      conn.exec_params(sql, binds, *args)
    end

    def sql
      return query unless should_rebuild?

      @sql || (rebuild_query! && @sql)
    end

    def binds
      return args unless should_rebuild?

      @binds || (rebuild_query! && @binds)
    end

    private

    def should_rebuild?
      args.any? { |param| param.is_a?(Array) }
    end

    def rebuild_query!
      @param_idx = 0
      @ref_idx = 1
      @binds = []
      each_param_ref do |value|
        # puts({value_before: value}.inspect)

        if args[@param_idx].is_a? Array
          value[KIND] = IN_KIND
          value[REXPR] = []
          args[@param_idx].each do |param|
            raise Error, "Param: #{param.inspect} not primitive" if param.respond_to?(:each)

            value[REXPR] << { PARAM_REF => { NUMBER => @ref_idx } }
            @binds << param
            @ref_idx += 1
          end
        else
          value[REXPR][PARAM_REF][NUMBER] = @ref_idx
          @ref_idx += 1

          # nested_refs == 1 unwraps, wrap it back
          value[REXPR] = [value[REXPR]] if value[KIND] == IN_KIND

          @binds << args[@param_idx]
        end

        @param_idx += 1
        # puts({value_after_: value}.inspect)
      end
      @sql = tree.deparse
      # puts({sql: @sql, binds: @binds}.inspect)
      true
    end

    def tree
      @tree ||= PgQuery.parse(query)
    end

    def each_param_ref
      tree.send :treewalker!, tree.tree do |_expr, key, value, _location|
        if key == A_EXPR
          if assign_param_via_eq?(value)
            yield value
          elsif (nested_refs = assign_param_via_in?(value))
            if nested_refs == 1
              value[REXPR] = value[REXPR].first
              yield value
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
      end
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
