module CompositePrimaryKeys
  ID_SEP     = ','
  ID_SET_SEP = ';'

  module ArrayExtension
    def to_composite_keys
      CompositeKeys.new(self)
    end
  end

  def self.normalize(ids)
    ids.map do |id|
      if id.is_a?(Array)
        normalize(id)
      elsif id.is_a?(String) && id.index(ID_SEP)
        id.split(ID_SEP)
      else
        id
      end
    end
  end

  class CompositeKeys < Array

    def self.parse(value)
      case value
      when Array
        value.to_composite_keys
      when String
        self.new(value.split(ID_SEP))
      else
        raise(ArgumentError, "Unsupported type: #{value}")
      end
    end

    def in(other)
      case other
        when Arel::SelectManager
          CompositePrimaryKeys::Nodes::In.new(self, other.ast)
      end
    end


    def to_s
      # Doing this makes it easier to parse Base#[](attr_name)
      join(ID_SEP)
    end
  end
end

Array.send(:include, CompositePrimaryKeys::ArrayExtension)
