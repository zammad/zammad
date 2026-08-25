# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Assigns the submitted title to a category, in one knowledge base locale.
module Service::KnowledgeBase::Category::Concerns::AssignsTitle
  extend ActiveSupport::Concern

  private

  # Upsert, never destroy: the title of the given locale is set, every other locale keeps the title
  #   it already has. A form edits one locale at a time, so a title arriving for that locale must
  #   not be able to blank another one.
  #
  # Assigns in memory only. The caller saves the category once, together with `parent_id`, so
  #   KnowledgeBase::HasUniqueTitle — which scopes sibling uniqueness through the category's
  #   `parent_id` — validates the title against the *new* siblings.
  def assign_title(category, kb_locale, title)
    return if title.nil?

    translation_for(category, kb_locale).title = title
  end

  def translation_for(category, kb_locale)
    category.translations.detect { |translation| translation.kb_locale_id == kb_locale.id } ||
      category.translations.build(kb_locale: kb_locale)
  end
end
