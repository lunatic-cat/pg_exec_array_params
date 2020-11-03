# frozen_string_literal: true

module PgExecArrayParams
  module Rewriters
    class Node
      attr_reader :value, :ref_idx

      def initialize(value, ref_idx)
        @value = value
        @ref_idx = ref_idx
      end

      def process
        rewrite! if should_rewrite?
      end

      # used in exception rendering
      def to_s
        return '<unknown node position>' unless (from, size = refs_at)

        "#{'^'.rjust(from, ' ')}#{'-'.rjust(size, '-')}^"
      end

      private

      # returns start and end index of value string repr inside query
      # [from, size]
      def refs_at; end

      def should_rewrite?; end

      def rewrite!; end
    end
  end
end
