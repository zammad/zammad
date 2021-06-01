# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TransactionJob < ApplicationJob

=begin
  {
    object: 'Ticket',
    type: 'update',
    ticket_id: 123,
    interface_handle: 'application_server', # application_server|websocket|scheduler
    changes: {
      'attribute1' => [before,now],
      'attribute2' => [before,now],
    },
    created_at: Time.zone.now,
    user_id: 123,
  },
=end

  def perform(item, params = {})
    Setting.where(area: 'Transaction::Backend::Async').order(:name).each do |setting|
      backend = Setting.get(setting.name)
      next if params[:disable]&.include?(backend)

      TransactionDispatcher.execute_single_backend(backend.constantize, item, params)
    end
  end
end
