class FixedStoreUpgrade45 < ActiveRecord::Migration[5.0]
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')
    Cache.clear
    [Macro, Taskbar, Calendar, Trigger, Channel, Job, PostmasterFilter, Report::Profile, Setting, Sla, Template].each do |class_name|
      class_name.all.each do |record|
        begin
          record.save!
        rescue => e
          Rails.logger.error "Unable to save/update #{class_name}.find(#{record.id}): #{e.message}"
        end
      end
    end
  end
end
