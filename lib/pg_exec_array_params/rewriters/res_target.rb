# frozen_string_literal: true

module PgExecArrayParams
  module Rewriters
    class ResTarget < Node
      VAL = 'val'

      def should_rewrite?
        plain_selection?
      end

      def rewrite!
        # puts({value_before: value}.inspect)
        old_ref_idx = value[VAL][PARAM_REF][NUMBER] - 1 # one based
        unless (new_ref_idx = ref_idx[old_ref_idx])
          raise Error.new("No parameter for $#{old_ref_idx + 1}", nil, self)
        end

        if new_ref_idx.is_a?(Array)
          elements = Range.new(*new_ref_idx).map do |param_ref_idx|
            { PARAM_REF => { NUMBER => param_ref_idx } }
          end
          value[VAL] = { 'A_ArrayExpr' => { 'elements' => elements } }
        else
          value[VAL][PARAM_REF][NUMBER] = new_ref_idx
        end
        # puts({value_after_: value, 'ref_idx' => ref_idx}.inspect)
      end

      # handle "select $1"
      # {"val"=>{"ParamRef"=>{"number"=>1, "location"=>7}}, "location"=>7}
      # AExpr handles "select $1 + 1"
      def plain_selection?
        value.key?(VAL) && value[VAL].is_a?(Hash) && value[VAL].key?(PARAM_REF)
      end

      def refs_at
        [value[VAL][PARAM_REF][LOCATION] + 1, value[VAL][PARAM_REF][NUMBER].to_s.size]
      end
    end
  end
end
