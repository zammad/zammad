module Import
  class ModelResource < Import::BaseResource

    def import_class
      model_name.constantize
    end

    def model_name
      @model_name ||= self.class.name.split('::').last
    end

    private

    def create(resource, *_args)
      result = super
      if !@dry_run
        reset_primary_key_sequence(model_name.underscore.pluralize)
      end
      result
    end
  end
end
