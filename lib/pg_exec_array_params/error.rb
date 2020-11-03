# frozen_string_literal: true

module PgExecArrayParams
  class Error < StandardError
    attr_accessor :query, :node

    def initialize(message, query = nil, node = nil)
      super(message)
      @msg = message
      @query = query
      @node = node
    end

    def to_s
      "#{@msg}\n#{@query}\n#{@node}"
    end
  end
end
