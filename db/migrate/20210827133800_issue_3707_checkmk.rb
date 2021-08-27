# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue3707Checkmk < ActiveRecord::Migration[6.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.find_by(name: 'check_mk_auto_close').update(options: {
                                                          form: [
                                                            {
                                                              display: '',
                                                              null:    true,
                                                              name:    'check_mk_auto_close',
                                                              tag:     'boolean',
                                                              options: {
                                                                true  => 'yes',
                                                                false => 'no',
                                                              },
                                                            },
                                                          ],
                                                        })
  end
end
