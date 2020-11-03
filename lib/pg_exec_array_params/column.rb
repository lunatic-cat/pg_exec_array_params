# frozen_string_literal: true

module PgExecArrayParams
  class Column
    attr_reader :table, :column_name, :as_name

    def initialize(table:, column_name:, as_name:)
      @table = table
      @column_name = column_name
      @as_name = as_name
    end

    def name
      @as_name || @column_name
    end

    def self.from_res_target(res_target)
      return unless (column_ref = res_target.fetch('val', {})['ColumnRef'])

      idents = column_ref['fields'].map { |field| field.fetch('String', {})['str'] }
      if idents.size <= 1
        column_name = idents.first
      else
        table, column_name, = idents
      end

      return unless column_name

      new(table: table, column_name: column_name, as_name: res_target['name'])
    end
  end
end
