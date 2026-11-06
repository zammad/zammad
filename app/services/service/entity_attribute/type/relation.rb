# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A select whose values are records — a ticket's state, priority, group or owner —, given by a record's name and set as
#   the record. Only records the user may choose are matched and listed.
class Service::EntityAttribute::Type::Relation < Service::EntityAttribute::Type
  def label(value)
    found = record_for(value)

    found && record_label(found)
  end

  # @return [ApplicationModel, nil] the record a stored value stands for, whether the user may choose it or not
  def record_for(value)
    record_class.find_by(id: value)
  end

  # @param allowed [Array<String>, nil] the stored values Core Workflow allows, nil for every value
  # @return [ActiveRecord::Relation] the records a caller may choose, in the order the ticket form lists them
  def records(allowed: nil)
    choosable(allowed)
  end

  def settable?
    true
  end

  def value_schema
    { type: 'string' }
  end

  def choices(allowed: nil)
    choosable(allowed).map { |record| [record.id.to_s, record_label(record)] }
  end

  def option_list(allowed: nil)
    choosable(allowed).map { |record| Option.new(value: record.id.to_s, label: option_label(record)) }
  end

  # The record itself, under the attribute's name without "_id".
  def data_key
    name.delete_suffix('_id')
  end

  private

  def convert(value, allowed:)
    Service::EntityAttribute::NameMatch.match(value.to_s.squish, choosable(allowed).to_a, filter: data_key, kind: data_key, label: ->(record) { record_label(record) })
  end

  # The records the user may choose, those Core Workflow allows where it is given.
  def choosable(allowed)
    records = if allowed.nil?
                scope
              elsif workflow_decides?
                record_class.where(id: allowed.compact_blank)
              else
                scope.where(id: allowed.compact_blank)
              end

    records.reorder(order)
  end

  # Whether Core Workflow's values are the choices, also one a workflow adds, as for a field whose save takes any record.
  #   A field whose save depends on the user's access, a group or an owner, keeps to the records the user may choose.
  def workflow_decides?
    false
  end

  # The record's own value stays a choice after it was switched off, as Core Workflow keeps it in the form.
  def scope
    return every if unscoped?
    return candidates if own_value.blank?

    record_class.where(id: candidates.select(:id)).or(record_class.where(id: own_value))
  end

  def own_value
    record[name] if record.respond_to?(:persisted?) && record.persisted?
  end

  # @return [ActiveRecord::Relation] every record the field may hold, for a caller that acts for nobody
  def every
    record_class.where(active: true)
  end

  # The order the ticket form lists the records in.
  def order
    { id: :asc }
  end

  # @return [Class] the model of the records
  def record_class
    raise NotImplementedError
  end

  # @return [ActiveRecord::Relation] the records the user may choose
  def candidates
    raise NotImplementedError
  end

  def record_label(record)
    record.name
  end

  # A record's own label in a list, which names its parents itself where it has them.
  def option_label(record)
    record_label(record)
  end
end
