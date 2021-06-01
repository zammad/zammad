# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Update assigned organization change_time information on user changes.
module User::TouchesOrganization
  extend ActiveSupport::Concern

  included do
    after_create  :touch_user_organization
    after_update  :touch_user_organization
    after_destroy :touch_user_organization
  end

  private

  def touch_user_organization

    # return if we run import mode
    return true if Setting.get('import_mode')

    organization_id_changed = saved_changes['organization_id']
    return true if !organization_id_changed

    return true if organization_id_changed[0] == organization_id_changed[1]

    # touch old organization
    if organization_id_changed[0]
      old_organization = Organization.find(organization_id_changed[0])
      old_organization&.touch # rubocop:disable Rails/SkipsModelValidations
    end

    # touch new/current organization
    organization&.touch # rubocop:disable Rails/SkipsModelValidations

    true
  end
end
