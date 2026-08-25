# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Updates a knowledge base: its texts in one locale, and its granular permissions.
class Service::KnowledgeBase::Update < Service::KnowledgeBase::Base
  include Service::KnowledgeBase::Concerns::AppliesPermissions

  # Authorizes through KnowledgeBasePolicy, which needs a user.
  requires_current_user!

  attr_reader :knowledge_base_data

  # @param knowledge_base_data [Hash] `title`, `footer_note` and `permissions` as sent by
  #   Gql::Types::Input::KnowledgeBase::InputType; `title` and `footer_note` are mandatory,
  #   `permissions` is optional
  # @param kb_locale [KnowledgeBase::Locale, String] locale the submitted texts are for, as record
  #   or as system locale code
  def initialize(knowledge_base_data:, kb_locale:)
    @knowledge_base_data = knowledge_base_data
    @submitted_kb_locale = kb_locale
  end

  def execute
    knowledge_base = active_knowledge_base!

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
    translation = translation_for

    translation.title       = knowledge_base_data[:title]
    translation.footer_note = knowledge_base_data[:footer_note]
  end

  # A locale added after the knowledge base was created has no translation yet (only
  #   KnowledgeBase#set_defaults seeds them, and it runs once on create), so one may have to be
  #   built here.
  def translation_for
    active_knowledge_base!.translations.detect { |translation| translation.kb_locale_id == kb_locale.id } ||
      active_knowledge_base!.translations.build(kb_locale: kb_locale)
  end
end
