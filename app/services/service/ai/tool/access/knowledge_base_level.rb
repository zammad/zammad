# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# How much of the knowledge base a caller may read at most: "editor" every answer, "reader" the internally and publicly
#   published ones, "published" the published ones only, as the public help site shows them. Read from the caller's
#   permissions, which a personal access token narrows to its own, while the knowledge base's own checks read the
#   user's roles; the knowledge base's categories may narrow it further.
module Service::AI::Tool::Access::KnowledgeBaseLevel
  LEVELS = %w[editor reader published].freeze

  # @param user [User] the caller, inside the token's context where a token authenticated the call
  # @return [String] one of LEVELS
  def self.of(user)
    return 'editor' if user.permissions?('knowledge_base.editor')
    return 'reader' if user.permissions?('knowledge_base.reader')

    'published'
  end

  # What the knowledge base's policy allowed the user, narrowed to the caller's level: an answer above it is not
  #   readable, and at the published level only the fields the public help site shows are. Any other record passes as
  #   its policy answered.
  #
  # @param record [ApplicationModel] a record a tool returns
  # @param result [Boolean, ApplicationPolicy::FieldScope] what the record's policy answered for the user
  # @param user [User] the caller, inside the token's context where a token authenticated the call
  # @return [Boolean, ApplicationPolicy::FieldScope]
  def self.cap(record, result, user)
    answer = record.is_a?(KnowledgeBase::Answer::Translation) ? record.answer : record
    return result if !result || !answer.is_a?(KnowledgeBase::Answer)

    case of(user)
    when 'editor'
      result
    when 'reader'
      answer.visible_internally? && result
    else
      answer.visible? && Pundit.policy(nil, answer).show?
    end
  end
end
