# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SettingUpdateKarmaLevel < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.set(
      'karma_levels',
      [
        {
          name:  'Beginner',
          start: 0,
          end:   499,
        },
        {
          name:  'Newbie',
          start: 500,
          end:   1999,
        },
        {
          name:  'Intermediate',
          start: 2000,
          end:   4999,
        },
        {
          name:  'Professional',
          start: 5000,
          end:   6999,
        },
        {
          name:  'Expert',
          start: 7000,
          end:   8999,
        },
        {
          name:  'Master',
          start: 9000,
          end:   18_999,
        },
        {
          name:  'Evangelist',
          start: 19_000,
          end:   49_999,
        },
        {
          name:  'Hero',
          start: 50_000,
          end:   nil,
        }
      ],
    )
  end
end
