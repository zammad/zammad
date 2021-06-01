# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue1977RemoveInvalidUserForeignKeys < ActiveRecord::Migration[5.1]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # cleanup
    OnlineNotification.joins('LEFT OUTER JOIN users ON online_notifications.user_id = users.id')
                      .where('users.id' => nil)
                      .destroy_all

    RecentView.joins('LEFT OUTER JOIN users ON recent_views.created_by_id = users.id')
              .where('users.id' => nil)
              .destroy_all

    Avatar.joins('LEFT OUTER JOIN users ON avatars.o_id = users.id')
          .where('users.id' => nil)
          .where(object_lookup_id: ObjectLookup.by_name('User'))
          .destroy_all

    # add (possibly) missing foreign_key
    foreign_keys = [
      %i[online_notifications users],
    ]

    foreign_keys.each do |args|

      add_foreign_key(*args)
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.info "Can't add foreign_keys '#{args.inspect}'"
      Rails.logger.info e
      ActiveRecord::Base.connection.reconnect!

    end
  end
end
