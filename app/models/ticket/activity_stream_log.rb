# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module Ticket::ActivityStreamLog

=begin

log activity for this object

  ticket = Ticket.find(123)
  result = ticket.activity_stream_log('create', user_id)

returns

  result = true # false

=end

  def activity_stream_log(type, user_id)

    # return if we run import mode
    return if Setting.get('import_mode')

    # return if we run on init mode
    return if !Setting.get('system_init_done')

    return if !self.class.activity_stream_support_config
    permission = self.class.activity_stream_support_config[:permission]
    ActivityStream.add(
      o_id: self['id'],
      type: type,
      object: self.class.name,
      group_id: self['group_id'],
      permission: permission,
      created_at: updated_at,
      created_by_id: user_id,
    )
  end
end
