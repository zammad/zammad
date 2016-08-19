class UpdateSettingPostmasterFilter2 < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')
    Setting.create_if_not_exists(
      title: 'Define postmaster filter.',
      name: '0012_postmaster_filter_sender_is_system_address',
      area: 'Postmaster::PreFilter',
      description: 'Define postmaster filter to check if email got created via email as Zammad.',
      options: {},
      state: 'Channel::Filter::SenderIsSystemAddress',
      frontend: false
    )
  end
end
