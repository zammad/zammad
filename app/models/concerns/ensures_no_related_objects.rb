# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module EnsuresNoRelatedObjects
  extend ActiveSupport::Concern

  included do
    before_destroy :ensures_no_related_objects
  end

  class_methods do
    def ensures_no_related_objects_classes
      # this cache doesn't need to be cleared as the result won't change
      @ensures_no_related_objects_classes ||= Models
                              .all
                              .keys
                              .select { |klass| klass.column_names.include? 'perform' }
    end

    def ensures_no_related_objects_path(*path)
      @path = path if path.present?

      @path
    end
  end

  def ensures_no_related_objects
    validator = EnsuresNoRelatedObjects.new(self)
    return if !validator.references?

    raise Exceptions::UnprocessableEntity
      .new __('This object is referenced by other object(s) and thus cannot be deleted: %s'), [validator.references_text]
  end

  class EnsuresNoRelatedObjects
    attr_reader :record

    def initialize(record)
      @record = record
    end

    def references?
      references.any?
    end

    def references
      @references ||= record.class.ensures_no_related_objects_classes.each_with_object({}) do |model, result|
        performables = referencing_objects(model)
        next if performables.blank?

        result[model.name] = performables
      end
    end

    def referencing_objects(model)
      model.find_each.with_object([]) do |performable, result|
        next if !referenced_in?(performable)

        result.push(performable.slice(:id, :name))
      end
    end

    def referenced_in?(performable)
      record.id == performable.perform
        &.dig(*record.class.ensures_no_related_objects_path)
        &.to_i
    end

    def references_text
      references.map do |model, performables|
        performables_text = performables
          .map { |performable| "#{performable[:name]} (##{performable[:id]})" }
          .join(', ')

        "#{model} / #{performables_text}"
      end.join(', ')
    end
  end
end
