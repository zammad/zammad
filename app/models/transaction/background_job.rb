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
    if Gem::Version.new(Version.get) >= Gem::Version.new('4.0.x')
      ActiveSupport::Deprecation.warn("This file has been migrated to the ActiveJob 'TransactionJob' and is therefore deprecated and should get removed.")
    end

    TransactionJob.perform_now(@item, @params)
  end
end
