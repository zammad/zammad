# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module HasKnowledgeBaseAttachmentPermissions
  extend ActiveSupport::Concern

  class_methods do
    def can_show_attachment?(file, user)
      return true if user_kb_editor?(user)

      object = find(file.o_id)

      return object&.visible_internally? if user_kb_reader?(user)

      object&.visible?
    end

    def can_destroy_attachment?(_file, user)
      return if !user_kb_editor?(user)

      true
    end

    def user_kb_editor?(user)
      return false if user.nil?

      user.permissions? %w[knowledge_base.editor]
    end

    def user_kb_reader?(user)
      return false if user.nil?

      user.permissions? %w[knowledge_base.reader]
    end
  end

  included do
    private_class_method :user_kb_editor?
  end
end
