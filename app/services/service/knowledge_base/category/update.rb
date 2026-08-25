# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Updates a knowledge base category: its title in one locale, its icon, its place in the tree and
#   its granular permissions.
class Service::KnowledgeBase::Category::Update < Service::KnowledgeBase::Category::Base
  attr_reader :category, :category_data

  # @param category [KnowledgeBase::Category] category to update
  # @param category_data [Hash] `category_icon`, `title`, `parent` and `permissions` as sent by
  #   Gql::Types::Input::KnowledgeBase::CategoryInputType; each is optional
  # @param kb_locale [KnowledgeBase::Locale, String] locale the submitted title is for, as record
  #   or as system locale code
  def initialize(category:, category_data:, kb_locale:)
    @category            = category
    @category_data       = category_data
    @submitted_kb_locale = kb_locale
  end

  def execute
    # Editing a category is editing knowledge base content, so it follows the same rule as the
    #   knowledge base itself: only while it is active. Asserted here rather than left to the locale
    #   resolution, which a caller passing a KnowledgeBase::Locale record would skip.
    active_knowledge_base!

    ActiveRecord::Base.transaction do
      assign_attributes

      authorize!

      # One single save, so the sibling title uniqueness of KnowledgeBase::HasUniqueTitle is checked
      #   against the siblings at the *new* place, and a rejected move does not leave a saved title
      #   behind.
      category.save!

      apply_permissions(category, category_data[:permissions])

      category
    end
  end

  private

  def assign_attributes
    category.parent = category_data[:parent] if parent_submitted?
    category.category_icon = category_data[:category_icon] if category_data[:category_icon].present?

    assign_title(category, kb_locale, category_data[:title])
  end

  # Editor access to the category is what allows editing it. A *move* additionally has to be allowed
  #   at the target, which CategoryPolicy#create? answers for the already reparented record (for a
  #   move to the top level that is the knowledge base itself).
  #
  #   Only an actual change is authorized that way, never a resubmitted unchanged parent: a granular
  #   editor may have editor access to the category while its parent is reader-only for them, and
  #   renaming it has to stay possible — the form sends the stored parent back on every save
  #   (see FormUpdater::Updater::KnowledgeBase::Category::Edit#initial_parent_value).
  def authorize!
    Pundit.authorize current_user, category, :update?
    Pundit.authorize current_user, category, :create? if category.parent_id_changed?
  end

  # A submitted `null` moves the category to the top level, while an absent key leaves it where it
  #   is — so the two cannot be told apart by the value.
  def parent_submitted?
    category_data.key?(:parent)
  end
end
