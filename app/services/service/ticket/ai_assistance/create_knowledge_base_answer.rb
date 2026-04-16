# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::AIAssistance::CreateKnowledgeBaseAnswer < Service::BaseWithCurrentUser
  attr_reader :ticket, :knowledge_base_id

  def initialize(current_user:, ticket:, knowledge_base_id:)
    super(current_user:)

    @ticket = ticket
    @knowledge_base_id = knowledge_base_id
  end

  def execute
    context = build_context!

    ai_result = request_ai_result(
      locale:         context[:locale],
      knowledge_base: context[:knowledge_base]
    )

    raise Exceptions::UnprocessableEntity, __('Knowledge base draft could not be generated.') if ai_result&.content.blank?

    kb_answer = Service::KnowledgeBase::CreateAnswerFromAIResult.new(
      ai_result:       ai_result.content,
      knowledge_base:  context[:knowledge_base],
      kb_locale:       context[:kb_locale],
      current_user_id: current_user.id
    ).execute

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
    raise Exceptions::UnprocessableEntity, __('Knowledge base is unavailable or not properly configured.') if knowledge_base.blank? || !knowledge_base.visible? || !knowledge_base.categories.exists?

    kb_locale = default_kb_locale(knowledge_base)

    {
      knowledge_base:,
      kb_locale:,
      locale:         kb_locale.system_locale.locale
    }
  end

  def default_kb_locale(knowledge_base)
    kb_locale = knowledge_base.kb_locales.find_by(primary: true) || knowledge_base.kb_locales.first
    raise Exceptions::UnprocessableEntity, __('No knowledge base locale configured.') if kb_locale.blank?

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

    raise Exceptions::UnprocessableEntity, __('No editable knowledge base categories available.') if editable_categories.empty?

    Service::Ticket::AIAssistance::GenerateKnowledgeBaseAnswerContent.new(
      locale:,
      ticket:,
      current_user:,
      category_options: knowledge_base_category_options(editable_categories)
    ).execute
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
