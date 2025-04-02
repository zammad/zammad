# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::UploadCachesControllerPolicy < Controllers::ApplicationControllerPolicy
  def update?
    permission?
  end

  def destroy?
    permission?
  end

  def remove_item?
    permission?(record.params[:store_id])
  end

  private

  def permission?(attachment_id = nil)
    attachments = UploadCache.new(record.params[:id]).attachments
    return true if attachments.blank?

    attachment = attachment_id ? attachments.find(attachment_id) : attachments.first

    attachment.created_by_id == user.id
  end
end
