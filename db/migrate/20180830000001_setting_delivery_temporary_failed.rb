class SettingDeliveryTemporaryFailed < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Defines postmaster filter.',
      name:        '0955_postmaster_filter_bounce_delivery_temporary_failed',
      area:        'Postmaster::PreFilter',
      description: 'Defines postmaster filter to identify postmaster bounced - reopen ticket on permanent temporary failed.',
      options:     {},
      state:       'Channel::Filter::BounceDeliveryTemporaryFailed',
      frontend:    false
    )

  end

end
