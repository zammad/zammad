# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Creates a knowledge base category, with its title in one locale and its granular permissions.
class Service::KnowledgeBase::Category::Create < Service::KnowledgeBase::Category::Base
  attr_reader :category_data

  # @param category_data [Hash] `category_icon`, `title`, `parent` and `permissions` as sent by
  #   Gql::Types::Input::KnowledgeBase::CategoryInputType; without a parent the category is created
  #   at the top level
  # @param kb_locale [KnowledgeBase::Locale, String] locale the submitted title is for, as record
  #   or as system locale code
  def initialize(category_data:, kb_locale:)
    @category_data       = category_data
    @submitted_kb_locale = kb_locale
  end

  def parent
    category_data[:parent]
  end

  def execute
    ActiveRecord::Base.transaction do
      category = build_category

      # For a top level category this asks the knowledge base itself, since CategoryPolicy#create?
      #   authorizes against `parent || knowledge_base` — which is what keeps a granular editor of
      #   one subtree from creating at the root.
      Pundit.authorize current_user, category, :create?

      category.save!

      apply_permissions(category, category_data[:permissions])

      category
    end
  end

  private

  def build_category
    knowledge_base = active_knowledge_base!

    ::KnowledgeBase::Category.new(
      knowledge_base: knowledge_base,
      parent:         parent,
      # The form supplies the knowledge base default as the field's initial value, so this only
      #   catches a client that leaves the icon out entirely — the model requires one.
      category_icon:  category_data[:category_icon].presence || knowledge_base.default_category_icon,
    ).tap do |category|
      assign_title(category, kb_locale, category_data[:title])
      ensure_title_present!(category)
    end
  end

  # The model has no such validation: a category without a single translation saves fine and then
  #   shows up as a nameless row in every list.
  def ensure_title_present!(category)
    return if category.translations.any?

    raise Exceptions::UnprocessableContent, __('A title is required.')
  end
end
