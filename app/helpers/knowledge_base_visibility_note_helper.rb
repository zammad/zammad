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
    case object.can_be_published_aasm.current_state
    when :internal
      'internal'
    when :archived
      'archived'
    when :draft
      'not published'
    end
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
