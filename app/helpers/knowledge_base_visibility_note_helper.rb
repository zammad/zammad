# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module KnowledgeBaseVisibilityNoteHelper
  def visibility_note(object)
    return if !current_user&.permissions?('knowledge_base.editor')

    text = visibility_text(object)

    return if text.nil?

    render 'knowledge_base/public/visibility_note', text: text
  end

  def visibility_text(object)
    case object
    when CanBePublished
      visiblity_text_can_be_published(object)
    when KnowledgeBase::Category
      visiblity_text_category(object)
    end
  end

  def visiblity_text_can_be_published(object)
    state_text_map = {
      internal: 'internal',
      archived: 'archived',
      draft:    'not published',
    }
    state_text_map[object.can_be_published_aasm.current_state]
  end

  def visiblity_text_category(object)
    return if object.public_content?

    if object.self_with_children_answers.only_internal.any?
      'hidden, visible only internally'
    else
      'hidden, no published answers'
    end
  end
end
