# frozen_string_literal: true

module PgExecArrayParams
  # Calculates inclusive bounds of each element in a flattened list
  # Bounds are one-based (as sql ref indexes), single value for non-arrays
  # [1, [2, 3], 4, [5, 6, 7]] => [1, [2, 3], 4, [5, 7]]
  class SqlRefIndex
    attr_reader :array

    def initialize(array)
      @array = array
      @extra_items = 0
    end

    def [](key)
      sql_ref_index[key]
    end

    def sql_ref_index
      @sql_ref_index ||= array.map.with_index(1) do |item, idx|
        if item.is_a?(Array)
          add_extra_items = item.size
          add_extra_items -= 1 if add_extra_items.positive?
          [idx + @extra_items, idx + (@extra_items += add_extra_items)]
        else
          idx + @extra_items
        end
      end
    end
  end
end
