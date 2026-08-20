# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Updates a knowledge base: its texts in one locale, and its granular permissions.
class Service::KnowledgeBase::Update < Service::Base
  include Service::KnowledgeBase::Concerns::AppliesPermissions

  # Authorizes through KnowledgeBasePolicy, which needs a user.
  requires_current_user!

  attr_reader :knowledge_base, :knowledge_base_data, :kb_locale

  # @param knowledge_base [KnowledgeBase] knowledge base to update
  # @param knowledge_base_data [Hash] `title`, `footer_note` and `permissions` as sent by
  #   Gql::Types::Input::KnowledgeBase::InputType; `title` and `footer_note` are mandatory,
  #   `permissions` is optional
  # @param kb_locale [KnowledgeBase::Locale] locale the submitted texts are for
  def initialize(knowledge_base:, knowledge_base_data:, kb_locale:)
    @knowledge_base      = knowledge_base
    @knowledge_base_data = knowledge_base_data
    @kb_locale           = kb_locale
  end

  def execute
    ActiveRecord::Base.transaction do
      assign_texts

      Pundit.authorize current_user, knowledge_base, :update?

      knowledge_base.save!

      apply_permissions(knowledge_base, knowledge_base_data[:permissions])

      knowledge_base
    end
  end

  private

  # Upsert, never destroy: the texts of `kb_locale` are set, every other locale keeps what it has.
  #   `title` and `footer_note` are mandatory on the input, so both are always rewritten together.
  #
  # Assigns in memory only, the knowledge base is saved once afterwards, so
  #   HasTranslations#validate_translations reports translation errors as `translations.<attribute>`.
  def assign_texts
    ensure_locale_of_knowledge_base!

    translation = translation_for

    translation.title       = knowledge_base_data[:title]
    translation.footer_note = knowledge_base_data[:footer_note]
  end

  # A locale added after the knowledge base was created has no translation yet (only
  #   KnowledgeBase#set_defaults seeds them, and it runs once on create), so one may have to be
  #   built here.
  def translation_for
    knowledge_base.translations.detect { |translation| translation.kb_locale_id == kb_locale.id } ||
      knowledge_base.translations.build(kb_locale: kb_locale)
  end

  # Nothing in the schema ties the locale to a knowledge base, and the model does not either — a
  #   foreign locale would save fine and then never be rendered by anything.
  def ensure_locale_of_knowledge_base!
    return if kb_locale.knowledge_base_id == knowledge_base.id

    raise Exceptions::UnprocessableContent, __('The selected language does not belong to this knowledge base.')
  end
end
