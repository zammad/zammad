module ActiveRecord
  class Fixture
    silence_warnings do
      def find
        if model_class
          # CPK
          # model_class.unscoped do
          #   model_class.find(fixture[model_class.primary_key])
          # end
          model_class.unscoped do
            ids = self.ids(model_class.primary_key)
            model_class.find(ids)
          end
        else
          raise FixtureClassNotFound, "No class attached to find."
        end
      end

      def ids(key)
        if key.is_a? Array
          key.map {|a_key| fixture[a_key.to_s] }
        else
          fixture[key]
        end
      end
    end
  end
end
