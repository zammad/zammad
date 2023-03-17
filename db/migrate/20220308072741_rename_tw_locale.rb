# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class RenameTwLocale < ActiveRecord::Migration[6.0]
  # Copied from db/migrate/20180502015927_issue_1219_zhtw_locale_typo.rb as this
  #   needed to be re-executed.
  def change
    return if !Setting.exists?(name: 'system_init_done')

    if Locale.exists?(locale: 'zh-tw')
      Locale.find_by(locale: 'zj-tw')&.destroy
    else
      Locale.find_by(locale: 'zj-tw')&.update(locale: 'zh-tw')
    end

    Translation.where(locale: 'zj-tw')&.update_all(locale: 'zh-tw') # rubocop:disable Rails/SkipsModelValidations
    User.where('preferences LIKE ?', "%\nlocale: zj-tw\n%").each do |u|
      u.preferences[:locale] = 'zh-tw'
      u.save
    end
  end
end
