# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module KnowledgeBaseVisibilityClassHelper
  def visibility_class_name(object)
    return if !current_user&.permissions?('knowledge_base.editor')

    suffix = case object
             when CanBePublished
               visiblity_class_suffix_can_be_published(object)
             when KnowledgeBase::Category
               visiblity_class_suffix_category(object)
             end

    "kb-item--#{suffix}" if suffix
  end

  def visiblity_class_suffix_can_be_published(object)
    state_suffix_map = {
      internal: 'internal',
      archived: 'archived',
      draft:    'not-published',
    }
    state_suffix_map[object.can_be_published_aasm.current_state]
  end

  def visiblity_class_suffix_category(object)
    return if object.public_content?

    if object.self_with_children_answers.only_internal.any?
      'internal'
    else
      'empty'
    end
  end
end
