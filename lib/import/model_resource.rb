module Import
  class ModelResource < Import::BaseResource

    def import_class
      model_name.constantize
    end

    def model_name
      @model_name ||= self.class.name.split('::').last
    end

    private

    def post_create(_args)
      reset_primary_key_sequence(model_name.underscore.pluralize)
    end
  end
end
