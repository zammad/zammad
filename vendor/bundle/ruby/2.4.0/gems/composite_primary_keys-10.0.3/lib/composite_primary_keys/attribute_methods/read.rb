module ActiveRecord
  module AttributeMethods
    module Read
      silence_warnings do
        def read_attribute(attr_name, &block)
          # CPK
          if attr_name.kind_of?(Array) || attr_name.to_s == 'id'.freeze && @attributes.key?('id')
            _read_attribute(attr_name, &block)
          else
            name = attr_name.to_s
            # CPK
            #name = self.class.primary_key if name == 'id'.freeze
            name = self.class.primary_key if name == 'id'.freeze && !composite?
            _read_attribute(name, &block)
          end
        end

        def _read_attribute(attr_name)
          # CPK
          if attr_name.kind_of?(Array)
            attr_name.map {|name| @attributes.fetch_value(name.to_s)}
          else
            @attributes.fetch_value(attr_name.to_s) { |n| yield n if block_given? }
          end
        end
      end
    end
  end
end
