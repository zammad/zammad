module KnowledgeBaseTopBarHelper
  def kb_top_bar_color(object)
    case object
    when KnowledgeBase::Answer
      kb_answer_top_bar_color(object)
    when KnowledgeBase::Category
      kb_locale = object&.translation&.kb_locale
      object.public_content?(kb_locale) ? 'green' : 'yellow'
    when KnowledgeBase
      'green'
    end
  end

  def kb_answer_top_bar_color(answer)
    case answer.can_be_published_aasm.current_state
    when :draft
      'yellow'
    when :internal
      'blue'
    when :published
      'green'
    when :archived
      'grey'
    end
  end

  def kb_top_bar_tag(object)
    case object
    when KnowledgeBase::Answer
      object.can_be_published_aasm.current_state
    when KnowledgeBase::Category
      kb_locale = object&.translation&.kb_locale
      object.public_content?(kb_locale) ? 'Visible' : 'Invisible'
    when KnowledgeBase
      'Published'
    end
  end
end
