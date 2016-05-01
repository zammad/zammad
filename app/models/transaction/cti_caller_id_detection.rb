# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/
require 'signature_detection'

class Transaction::CtiCallerIdDetection

=begin
  {
    object: 'Ticket',
    type: 'create',
    object_id: 123,
    via_web: true,
    user_id: 123,
  },
  {
    object: 'User',
    type: 'update',
    object_id: 123,
    via_web: true,
    changes: {
      'attribute1' => [before, now],
      'attribute2' => [before, now],
    }
    user_id: 123,
  },
=end

  def initialize(item, params = {})
    @item = item
    @params = params
  end

  def perform

    # return if we run import mode
    return if Setting.get('import_mode')

    if @item[:object] == 'Ticket' && @item[:type] == 'create'
      ticket = Ticket.lookup(id: @item[:object_id])
      return if !ticket
      Cti::CallerId.build(ticket)
    end

    if @item[:object] == 'User'
      user = User.lookup(id: @item[:object_id])
      return if !user
      Cti::CallerId.build(user)
    end

  end

end
