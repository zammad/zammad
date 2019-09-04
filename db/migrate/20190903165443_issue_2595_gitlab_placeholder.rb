class Issue2595GitlabPlaceholder < ActiveRecord::Migration[5.2]
  def change
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    setting = Setting.find_by(name: 'auth_gitlab_credentials')
    setting.options['form'].last['placeholder'] = 'https://gitlab.YOURDOMAIN.com/api/v4/'
    setting.save!
  end
end
