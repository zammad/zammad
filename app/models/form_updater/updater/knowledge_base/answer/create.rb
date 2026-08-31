# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Form updater for adding a knowledge base answer. A supplied `id` is ignored, like
#   FormUpdater::Updater::Ticket::Create; editing goes through ::Edit.
#
# With no object behind the form yet, FormUpdater::Concerns::StoresTaskbarState stores every
#   submitted value — which is exactly what a draft needs.
class FormUpdater::Updater::KnowledgeBase::Answer::Create < FormUpdater::Updater
  include FormUpdater::Updater::KnowledgeBase::Answer::Concerns::HasCategoryField

  # The category the draft was opened for arrives with the first round trip and nothing follows it,
  #   so without this the tab would be reopened without it (see #seeded_category).
  store_state_on_initial

  def authorized?
    return false if !current_user.permissions?(self.class.required_permissions)
    return false if knowledge_base.nil?

    # Nowhere to file an answer: not a single category of the knowledge base is open to this user.
    #   Unlike a category, an answer has no top level to fall back on, so an empty option list
    #   does settle it.
    category_relation.selectable_categories.any?
  end

  # A new answer opens on `draft`, which the editor may change before filing it. No timing to seed
  #   alongside it: scheduling a state for later is an edit, so this form has no such field - what
  #   it picks takes effect as soon as the answer is created.
  def initial_values
    values = { 'visibility' => 'draft' }

    category = seeded_category
    values['categoryId'] = category.id if category

    values
  end

  private

  # A new answer goes into the active knowledge base, like every other desktop knowledge base
  #   query (Gql::Concerns::HandlesKnowledgeBaseLocale).
  def knowledge_base
    @knowledge_base ||= ::KnowledgeBase.active.first
  end

  # The category the tab was opened from. Nil when it was opened without one, which leaves the
  #   field for the user to pick: an `initialValue` from the updater always wins over what the
  #   client seeded (see Form.vue), so it must only go out when a category was really passed.
  #
  # Accepted as an internal id, the way FormUpdater::Updater::Ticket::Create takes its
  #   `customer_id` — and as a GraphQL id, which is what the same `additionalData` bag carries for
  #   `taskbarId`, so neither form of the seed is silently dropped.
  #
  # Resolved against the options that were actually offered, which also settles the authorization:
  #   a seed pointing at a category the user may not write to would preselect a value the field
  #   cannot even render.
  def seeded_category
    seeded_id = meta.dig(:additional_data, 'categoryId')
    return if seeded_id.blank?

    category_relation.selectable_categories.find do |category|
      [category.id.to_s, Gql::ZammadSchema.id_from_object(category)].include?(seeded_id.to_s)
    end
  end
end
