# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TicketHookSettingDescription < ActiveRecord::Migration[6.1]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting
      .find_by(name: 'ticket_hook_position')
      .update(description: <<~HTML.chomp)
        The format of the subject.
        * **Right** means **Some Subject [Ticket#12345]**
        * **Left** means **[Ticket#12345] Some Subject**
        * **None** means **Some Subject** (without ticket number), in which case it recognizes follow-ups based on email headers.
      HTML
  end
end
