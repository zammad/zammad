# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Webhook::EnsureNoRelatedObjects

  attr_reader :record

  def self.before_destroy(record)
    new(record).before_destroy
  end

  def self.referencing_models
    # this cache doesn't need to be cleared as the result won't change
    @referencing_models ||= Models
                            .all
                            .keys
                            .select { |klass| klass.column_names.include? 'perform' }
  end

  def initialize(record)
    @record = record
  end

  def before_destroy
    return if record.new_record?

    ensure_no_related_objects!
  end

  private

  def ensure_no_related_objects!
    return if related_objects.blank?

    raise Exceptions::UnprocessableEntity, "Cannot delete! This webhook is referenced by #{references_text}"
  end

  def related_objects
    @related_objects ||= self.class.referencing_models.each_with_object({}) do |model, result|
      performables = referencing_performables(model)
      next if performables.blank?

      result[model.name] = performables
    end
  end

  def referencing_performables(model)
    model.find_each.with_object([]) do |performable, result|
      next if !webhook_referenced?(performable)

      result.push({
                    id:   performable.id,
                    name: performable.name
                  })
    end
  end

  def webhook_referenced?(performable)
    record.id == performable.perform
      &.dig('notification.webhook', 'webhook_id')
      &.to_i
  end

  def references_text
    related_objects.map do |model, performables|
      performables_text = performables.map { |performable| "#{performable[:name]} (##{performable[:id]})" }.join(', ')
      "#{model}: #{performables_text}"
    end.join(', ')
  end
end
