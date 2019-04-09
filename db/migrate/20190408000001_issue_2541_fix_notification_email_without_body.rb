class Issue2541FixNotificationEmailWithoutBody < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    # update jobs and triggers
    [::Job, ::Trigger].each do |model|
      model.all.each do |record|
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
