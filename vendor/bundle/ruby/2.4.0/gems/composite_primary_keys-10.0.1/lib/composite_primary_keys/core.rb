module ActiveRecord
  module Core
    silence_warnings do
      def initialize_dup(other) # :nodoc:
        @attributes = @attributes.dup
        # CPK
        # @attributes.reset(self.class.primary_key)
        Array(self.class.primary_key).each {|key| @attributes.reset(key)}

        run_callbacks(:initialize) unless _initialize_callbacks.empty?

        @aggregation_cache = {}
        @association_cache = {}

        @new_record  = true
        @destroyed   = false

        super
      end
    end

    module ClassMethods
      silence_warnings do
        def find(*ids) # :nodoc:
          # We don't have cache keys for this stuff yet
          return super unless ids.length == 1
          return super if block_given? ||
                          primary_key.nil? ||
                          scope_attributes? ||
                          columns_hash.include?(inheritance_column)

          # CPK
          return super if self.composite?

          id = ids.first

          return super if id.kind_of?(Array) ||
                           id.is_a?(ActiveRecord::Base)

          key = primary_key

          statement = cached_find_by_statement(key) { |params|
            where(key => params.bind).limit(1)
          }

          record = statement.execute([id], self, connection).first
          unless record
            raise RecordNotFound.new("Couldn't find #{name} with '#{primary_key}'=#{id}",
                                     name, primary_key, id)
          end
          record
        rescue ::RangeError
          raise RecordNotFound.new("Couldn't find #{name} with an out of range value for '#{primary_key}'",
                                   name, primary_key)
        end
      end
    end
  end
end
