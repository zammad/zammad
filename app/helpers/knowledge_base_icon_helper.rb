# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module KnowledgeBaseIconHelper
  def icon_for_object(object, iconset)
    case object
    when KnowledgeBase::Category
      icon object.category_icon, iconset
    when KnowledgeBase::Answer
      icon 'knowledge-base-answer'
    when KnowledgeBase
      icon 'knowledge-base'
    when Array
      icon 'hashtag' # object[0] override while tag icon is available
    end
  end

  def icon(icon_identifier, iconset = nil)
    return icon_native(icon_identifier) if iconset.nil?

    icon_from_set(icon_identifier, iconset)
  end

  def icon_native(icon_identifier)
    render 'knowledge_base/public/icon_native', icon_identifier: icon_identifier
  end

  def icon_from_set(icon_identifier, iconset)
    render 'knowledge_base/public/icon_from_set', iconset: iconset, icon_identifier: icon_identifier
  end
end
