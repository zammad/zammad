# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue2401ConvertUserLoginEmailToUnicode < ActiveRecord::Migration[6.1]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    sql_regex = "%@%#{SimpleIDN::ACE_PREFIX}%"

    User.where('email like ? or login like ?', sql_regex, sql_regex).each do |user|
      user.update(login: EmailHelper::Idn.to_unicode(user.login), email: EmailHelper::Idn.to_unicode(user.email))
    end
  end
end
