module Cti
  class Log < ApplicationModel
    self.table_name = 'cti_logs'

    after_create :push_event, :push_caller_list
    after_update :push_event, :push_caller_list
    after_destroy :push_event, :push_caller_list

=begin

  Cti::Log.create(
    direction: 'in',
    from: '007',
    from_comment: '',
    to: '008',
    to_comment: '',
    call_id: '1',
    comment: '',
    state: 'newCall',
  )

  Cti::Log.create(
    direction: 'in',
    from: '007',
    from_comment: '',
    to: '008',
    to_comment: '',
    call_id: '2',
    comment: '',
    state: 'answer',
  )

  Cti::Log.create(
    direction: 'in',
    from: '009',
    from_comment: '',
    to: '010',
    to_comment: '',
    call_id: '3',
    comment: '',
    state: 'hangup',
  )

=end

    def push_event
      users = User.of_role('CTI')
      users.each {|user|

        # send notify about event
        Sessions.send_to(
          user.id,
          {
            event: 'cti_event',
            data: self,
          },
        )
      }
    end

    def push_caller_list
      list = Cti::Log.order('created_at DESC').limit(60)

      users = User.of_role('CTI')
      users.each {|user|

        # send notify on create/update/delete
        Sessions.send_to(
          user.id,
          {
            event: 'cti_list_push',
            data: list,
          },
        )
      }
    end
  end
end
