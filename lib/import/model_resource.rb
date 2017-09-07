module Import
  class ModelResource < Import::BaseResource

    def import_class
      self.class.import_class
    end

    def model_name
      self.class.model_name
    end

    def self.import_class
      model_name.constantize
    end

    def self.model_name
      @model_name ||= name.split('::').last
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
