# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Relation
  attr_reader :context, :current_user, :data, :filter_ids

  def initialize(context:, current_user:, data: {}, filter_ids: [])
    @context = context
    @current_user = current_user
    @data = data
    @filter_ids = filter_ids
  end

  def options
    items.map do |item|
      { value: item.id, label: display_name(item) }
    end
  end

  private

  def order
    { id: :asc }
  end

  def display_name(item)
    item.name
  end

  def relation_type
    raise NotImplementedError
  end

  def items
    @items ||= begin
      if filter_ids
        relation_type.where(id: filter_ids).reorder(order)
      else
        # Currently the default is an empty array, later we need some good solution for the admin area.
        []
      end
    end
  end
end
