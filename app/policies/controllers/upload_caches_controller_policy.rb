# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::UploadCachesControllerPolicy < Controllers::ApplicationControllerPolicy
  def update?
    permission?
  end

  def destroy?
    permission?
  end

  def remove_item?
    permission?
  end

  private

  def permission?
    Pundit.policy(user, UploadCache.new(record.params[:id]))&.any?
  end
end
