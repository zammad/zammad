# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Transaction::BackgroundJob
  def initialize(item, params = {})

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

    @item = item
    @params = params
  end

  def perform
    Setting.where(area: 'Transaction::Backend::Async').order(:name).each do |setting|
      backend = Setting.get(setting.name)
      next if @params[:disable]&.include?(backend)

      Observer::Transaction.execute_singel_backend(backend.constantize, @item, @params)
    end
  end

  def self.run(item, params = {})
    generic = new(item, params)
    generic.perform
  end

end
