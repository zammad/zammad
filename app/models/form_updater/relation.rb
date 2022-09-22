# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Relation
  attr_reader :context, :data, :filter_ids

  def initialize(context:, data: {}, filter_ids: [])
    @context = context
    @data    = data
    @filter_ids = filter_ids
  end

  def options
    options = []

    items.each do |item|
      options.push({ value: item.id, label: display_name(item) })
    end

    options
  end

  private

  # # If the context responds to :schema, use it to map the filter_ids to GraphQL::ID strings.
  # def id_from_object(object)
  #   context.try(:schema)&.id_from_object(object) || object.id
  # end

  def display_name(item)
    item.name
  end

  def relation_type
    raise NotImplementedError
  end

  def items
    @items ||= begin
      if filter_ids
        relation_type.where(id: filter_ids).order(id: :asc)
      end

      relation_type.where(active: true).order(id: :asc)
    end
  end
end
