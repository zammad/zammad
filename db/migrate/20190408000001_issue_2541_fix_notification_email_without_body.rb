class Issue2541FixNotificationEmailWithoutBody < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    # there might be Job/Trigger selectors referencing the current user
    # that get e.g. validated in callbacks
    UserInfo.current_user_id = 1

    # update jobs and triggers
    [::Job, ::Trigger].each do |model|
      model.where(active: true).each do |record|
        next if record.perform.blank?

        %w[notification.email notification.sms].each do |action|
          next if record.perform[action].blank?
          next if record.perform[action]['body'].present?

          record.perform[action]['body'] = '-'
          record.save!
        end
      end
    end

    # re-enable jobs again
    scheduler = Scheduler.find_by(method: 'Job.run')
    return if !scheduler
    return if scheduler.active?

    scheduler.update!(active: true)
  end
end
