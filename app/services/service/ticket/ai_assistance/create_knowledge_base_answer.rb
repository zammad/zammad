# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::AIAssistance::CreateKnowledgeBaseAnswer < Service::Base
  requires_current_user!

  attr_reader :ticket, :knowledge_base_id

  def initialize(ticket:, knowledge_base_id:)
    @ticket            = ticket
    @knowledge_base_id = knowledge_base_id
  end

  def execute
    context = build_context!

    ai_result = request_ai_result(
      locale:         context[:locale],
      knowledge_base: context[:knowledge_base]
    )

    raise Exceptions::UnprocessableContent, __('Knowledge base draft could not be generated.') if ai_result&.content.blank?

    kb_answer = Service::KnowledgeBase::CreateAnswerFromAIResult
      .with_current_user(current_user)
      .execute(
        ai_result:      ai_result.content,
        knowledge_base: context[:knowledge_base],
        kb_locale:      context[:kb_locale],
      )

    link_answer_to_ticket(kb_answer)
    create_notification(kb_answer)

    {
      locale:            context[:locale],
      knowledge_base_id: context[:knowledge_base].id,
      answer_id:         kb_answer.id
    }
  end

  private

  def build_context!
    knowledge_base = KnowledgeBase.find_by(id: knowledge_base_id)
    raise Exceptions::UnprocessableContent, __('Knowledge base is unavailable or not properly configured.') if knowledge_base.blank? || !knowledge_base.visible? || !knowledge_base.categories.exists?

    kb_locale = default_kb_locale(knowledge_base)

    {
      knowledge_base:,
      kb_locale:,
      locale:         kb_locale.system_locale.locale
    }
  end

  def default_kb_locale(knowledge_base)
    kb_locale = knowledge_base.kb_locales.find_by(primary: true) || knowledge_base.kb_locales.first
    raise Exceptions::UnprocessableContent, __('No knowledge base locale configured.') if kb_locale.blank?

    kb_locale
  end

  def link_answer_to_ticket(kb_answer)
    translation = kb_answer.translations.first
    return if translation.blank?

    Link.add(
      link_type:                'normal',
      link_object_target:       'Ticket',
      link_object_target_value: ticket.id,
      link_object_source:       'KnowledgeBase::Answer::Translation',
      link_object_source_value: translation.id,
    )
  end

  def create_notification(kb_answer)
    translation = kb_answer.translations.first
    return if translation.blank?

    OnlineNotification.add(
      object:        'KnowledgeBase::Answer::Translation',
      o_id:          translation.id,
      type:          'create',
      user_id:       current_user.id,
      created_by_id: 1,
      seen:          false
    )
  end

  def request_ai_result(locale:, knowledge_base:)
    editable_categories = KnowledgeBase::AccessibleCategories
      .for_user(current_user, categories_filter: knowledge_base.categories.root)
      .editor

    raise Exceptions::UnprocessableContent, __('No editable knowledge base categories available.') if editable_categories.empty?

    Service::Ticket::AIAssistance::GenerateKnowledgeBaseAnswerContent
      .with_current_user(current_user)
      .execute(
        locale:,
        ticket:,
        category_options: knowledge_base_category_options(editable_categories)
      )
  end

  def knowledge_base_category_options(categories)
    categories.map do |category|
      {
        value: category.id,
        label: category.translation&.title,
      }
    end
  end

end
