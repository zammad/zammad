class ActiveRecord::ConnectionAdapters::NullDBAdapter

  class EmptyResult < Array
    attr_writer :columns
    def rows
      []
    end

    def column_types
      columns.map{|col| col.type}
    end

    def columns
      @columns ||= []
    end

    def cast_values(type_overrides = nil)
      rows
    end

    def >(num)
      rows.size > num
    end
  end

end
