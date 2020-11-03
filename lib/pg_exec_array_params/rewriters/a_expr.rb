# frozen_string_literal: true

module PgExecArrayParams
  module Rewriters
    class AExpr < Node
      KIND = 'kind'

      private

      def should_rewrite?
        return true if assign_param_via_eq?

        if (nested_refs = assign_param_via_in?)
          if nested_refs == 1
            value[REXPR] = value[REXPR].first
            return true
          else
            suggest_n = value[REXPR].first[PARAM_REF][NUMBER]
            raise Error.new("Leave only `= $#{suggest_n}` and pass an array", nil, self)
          end
        end
        false
      end

      def rewrite!
        # puts({value_before: value}.inspect)
        old_ref_idx = value[REXPR][PARAM_REF][NUMBER] - 1 # one based
        unless (new_ref_idx = ref_idx[old_ref_idx])
          raise Error.new("No parameter for $#{old_ref_idx + 1}", nil, self)
        end

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

      # = $1
      # {"kind"=>0, "name"=>[{"String"=>{"str"=>"="}}],
      #  "lexpr"=>{"ColumnRef"=>{"fields"=>[{"String"=>{"str"=>"companies"}}, {"String"=>{"str"=>"id"}}],
      #                          "location"=>1242}},
      #  "rexpr"=>{"ParamRef"=>{"number"=>4, "location"=>1261}}, "location"=>1259}
      def assign_param_via_eq?
        (value[KIND] == EQ_KIND) && value[REXPR].is_a?(Hash) && value[REXPR].key?(PARAM_REF)
      end

      # IN ($1), returns number of nested REFs
      def assign_param_via_in?
        (value[KIND] == IN_KIND) && value[REXPR].is_a?(Array) && value[REXPR].count { |vexpr| vexpr.key?(PARAM_REF) }
      end

      def refs_at
        first_ref = wrap_array(value[REXPR]).find { |vexpr| vexpr.key?(PARAM_REF) }&.fetch(PARAM_REF, {})
        last_ref = wrap_array(value[REXPR]).reverse.find { |vexpr| vexpr.key?(PARAM_REF) }&.fetch(PARAM_REF, {})
        return unless (start_ref_loc = first_ref[LOCATION])

        return unless (end_ref_loc = last_ref[LOCATION])

        started = start_ref_loc + 1
        ended = end_ref_loc + last_ref.fetch(NUMBER, '').to_s.size
        [started, ended - started]
      end

      def wrap_array(object)
        if object.respond_to?(:to_ary)
          object.to_ary || [object]
        else
          [object]
        end
      end
    end
  end
end
