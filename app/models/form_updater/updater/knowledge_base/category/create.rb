# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Form updater for adding a knowledge base category. A supplied `id` is ignored, like
#   FormUpdater::Updater::Ticket::Create; editing goes through ::Edit.
class FormUpdater::Updater::KnowledgeBase::Category::Create < FormUpdater::Updater
  include FormUpdater::Updater::KnowledgeBase::Category::Concerns::HasParentAndPermissions

  def authorized?
    return false if !current_user.permissions?(self.class.required_permissions)
    return false if knowledge_base.nil?

    # Nothing to create under: neither the knowledge base itself nor any of its categories is
    #   open to this user. The top level has to be asked for separately — it is not an option
    #   row but the absence of one, so an empty option list alone does not rule it out (an
    #   editor of a knowledge base without any categories yet is the everyday case).
    parent_relation.top_level_selectable? || parent_relation.options.any?
  end

  def resolve
    result['categoryIcon'] = { initialValue: knowledge_base.default_category_icon } if meta[:initial]

    super
  end

  private

  # A new category goes into the active knowledge base, like every other desktop knowledge base
  #   query (Gql::Concerns::HandlesKnowledgeBaseLocale).
  def knowledge_base
    @knowledge_base ||= ::KnowledgeBase.active.first
  end

  def excluded_category
    nil
  end

  # Nothing to preselect: an empty parent field is already the top level, which is where a new
  #   category goes by default. Leaving it unset also lets the form keep whatever the caller
  #   seeded — the browse view passes the category it was opened from — instead of overriding it
  #   (an `initialValue` from the updater always wins, see Form.vue).
  def initial_parent_value
    nil
  end

  def fallback_parent
    knowledge_base
  end
end
