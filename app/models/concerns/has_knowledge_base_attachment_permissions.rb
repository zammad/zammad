# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module HasKnowledgeBaseAttachmentPermissions
  extend ActiveSupport::Concern

  class_methods do
    def can_show_attachment?(file, user)
      return true if user_kb_editor?(user)

      find(file.o_id)&.visible?
    end

    def can_destroy_attachment?(file, user)
      return if !user_kb_editor?(user)
      return if !HasRichText.attachment_inline?(file)

      true
    end

    def user_kb_editor?(user)
      return false if user.nil?

      user.permissions? %w[knowledge_base.editor]
    end
  end

  included do
    private_class_method :user_kb_editor?
  end
end
