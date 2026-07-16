# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::UploadCachesControllerPolicy < Controllers::ApplicationControllerPolicy
  def update?
    permission?
  end

  def destroy?
    permission?
  end

  def remove_item?
    permission_for_item?(record.params[:store_id])
  end

  private

  def permission?
    attachments = UploadCache.new(record.params[:id]).attachments(created_by_id: nil)
    !attachments.exists? || attachments.exists?(created_by_id: user.id)
  end

  def permission_for_item?(attachment_id)
    UploadCache.new(record.params[:id])
      .attachments(created_by_id: user.id)
      .exists?(id: attachment_id)
  end
end
