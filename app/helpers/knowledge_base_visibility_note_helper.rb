# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module KnowledgeBaseVisibilityNoteHelper
  def visibility_note(object)
    return if !can_preview?

    text = visibility_text(object)

    return if text.nil?

    render 'knowledge_base/public/visibility_note', text: text
  end

  def visibility_text(object)
    case object
    when CanBePublished
      visibility_text_can_be_published(object)
    when KnowledgeBase::Category
      visibility_text_category(object)
    end
  end

  def visibility_text_can_be_published(object)
    state_text_map = {
      internal: __('internal'),
      archived: __('archived'),
      draft:    __('not published'),
    }
    state_text_map[object.can_be_published_aasm.current_state]
  end

  def visibility_text_category(object)
    return if object.public_content?

    if object.self_with_children_answers.only_internal.any?
      __('hidden, visible only internally')
    else
      __('hidden, no published answers')
    end
  end
end
