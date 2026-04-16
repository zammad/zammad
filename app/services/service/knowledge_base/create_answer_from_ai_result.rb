# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::KnowledgeBase::CreateAnswerFromAIResult < Service::Base
  attr_reader :ai_result, :knowledge_base, :current_user_id, :kb_locale

  def initialize(ai_result:, knowledge_base:, kb_locale:, current_user_id:)
    super()

    @ai_result       = ai_result
    @knowledge_base  = knowledge_base
    @kb_locale       = kb_locale
    @current_user_id = current_user_id
  end

  def execute
    validate_context!

    payload = draft_payload

    UserInfo.with_user_id(current_user_id) do
      ActiveRecord::Base.transaction do
        kb_answer = KnowledgeBase::Answer.new(category_id: payload[:category].id, promoted: false)
        translation = kb_answer.translations.build(
          title:     payload[:title].truncate(250),
          kb_locale:,
        )
        translation.build_content(body: payload[:body])
        kb_answer.save!
        kb_answer.tag_add('ai-generated', current_user_id)
        kb_answer
      end
    end
  end

  private

  def validate_context!
    raise Exceptions::UnprocessableEntity, __('No knowledge base locale configured.') if kb_locale.blank?
    raise Exceptions::UnprocessableEntity, __('Invalid knowledge base locale.')       if kb_locale.knowledge_base_id != knowledge_base.id
  end

  def draft_payload
    data = ai_result.is_a?(Hash) ? ai_result.deep_stringify_keys : {}

    category = resolve_category(data)

    {
      title:    resolve_title(data, category),
      body:     body_with_ai_note(data['body'].to_s.strip),
      category:,
    }
  end

  def body_with_ai_note(body)
    locale = kb_locale.system_locale.locale
    note   = Translation.translate(locale, 'Be sure to check AI-generated content for accuracy.')

    "#{body}<p><br><small><em>#{note}</em></small></p>"
  end

  def resolve_category(data)
    knowledge_base.categories.find_by(id: data['category_id'].to_i) || raise(Exceptions::UnprocessableEntity, __('No valid knowledge base category provided.'))
  end

  def resolve_title(data, category)
    title = data['title'].to_s.strip

    return title if !title_exists_in_category?(title, category)

    "#{title} (Duplicate #{SecureRandom.alphanumeric(4)})"
  end

  def title_exists_in_category?(title, category)
    KnowledgeBase::Answer::Translation
      .where(kb_locale: kb_locale, title: title)
      .joins(:answer)
      .exists?(knowledge_base_answers: { category_id: category.id })
  end
end
