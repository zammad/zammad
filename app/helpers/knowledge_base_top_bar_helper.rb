# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
    state_color_map = {
      draft:     'yellow',
      internal:  'blue',
      published: 'green',
      archived:  'grey',
    }
    state_color_map[answer.can_be_published_aasm.current_state]
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
