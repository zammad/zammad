require 'set'
class V8::Access
  module Names
    def names(obj)
      accessible_names(obj)
    end

    def get(obj, name, &dontintercept)
      methods = accessible_names(obj)
      if methods.include?(name)
        method = obj.method(name)
        method.arity == 0 ? method.call : method.unbind
      elsif obj.respond_to?(:[]) && !special?(name)
        obj.send(:[], name, &dontintercept)
      else
        yield
      end
    end

    def set(obj, name, value, &dontintercept)
      setter = name + "="
      methods = accessible_names(obj, true)
      if methods.include?(setter)
        obj.send(setter, value)
      elsif obj.respond_to?(:[]=) && !special?(name)
        obj.send(:[]=, name, value, &dontintercept)
      else
        yield
      end
    end

    def query(obj, name, attributes, &dontintercept)
      if obj.respond_to?(name)
        attributes.dont_delete
        unless obj.respond_to?(name + "=")
          attributes.read_only
        end
      else
        yield
      end
    end

    def delete(obj, name, &dontintercept)
      yield
    end

    def accessible_names(obj, special_methods = false)
      obj.public_methods(false).map {|m| m.to_s}.to_set.tap do |methods|
        ancestors = obj.class.ancestors.dup
        while ancestor = ancestors.shift
          break if ancestor == ::Object
          methods.merge(ancestor.public_instance_methods(false).map {|m| m.to_s})
        end
        methods.reject!(&special?) unless special_methods
      end
    end

    private

    def special?(name = nil)
      @special ||= lambda {|m| m == "[]" || m == "[]=" || m =~ /=$/}
      name.nil? ? @special : @special[name]
    end
  end
end