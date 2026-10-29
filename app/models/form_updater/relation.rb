# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Relation
  attr_reader :context, :current_user, :data, :filter_ids

  def initialize(context:, current_user:, data: {}, filter_ids: nil)
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

  # Scope of items returned when no explicit filter_ids are supplied. Default
  # is "nothing" — subclasses opt in by returning the set of items the
  # current user is allowed to see (e.g. via policy scope or a permission-
  # restricted association). Used by the advanced search filter form updater
  # so each filter field is pre-populated with everything the user could pick.
  #
  # TODO: a separate admin-context scope (unrestricted by current_user) will
  # be needed for the future admin interface — out of scope for now.
  def default_scope
    relation_type.none
  end

  # Items the current user may see at all. The filter ids come from the request or from core
  #   workflow, so they only ever narrow this down. Every relation has to declare it.
  def allowed_scope
    raise "#{self.class.name} needs to declare the items the current user may see."
  end

  def items
    @items ||= begin
      scope = filter_ids.nil? ? default_scope : relation_type.where(id: filter_ids)
      scope.and(allowed_scope).reorder(order)
    end
  end
end
