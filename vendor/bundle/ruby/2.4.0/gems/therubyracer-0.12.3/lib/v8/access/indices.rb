class V8::Access
  module Indices

    def indices(obj)
      obj.respond_to?(:length) ? (0..obj.length).to_a : []
    end

    def iget(obj, index, &dontintercept)
      if obj.respond_to?(:[])
        obj.send(:[], index, &dontintercept)
      else
        yield
      end
    end

    def iset(obj, index, value, &dontintercept)
      if obj.respond_to?(:[]=)
        obj.send(:[]=, index, value, &dontintercept)
      else
        yield
      end
    end

    def iquery(obj, index, attributes, &dontintercept)
      if obj.respond_to?(:[])
        attributes.dont_delete
        unless obj.respond_to?(:[]=)
          attributes.read_only
        end
      else
        yield
      end
    end

    def idelete(obj, index, &dontintercept)
      yield
    end

  end
end