# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The decision Cti::Driver::Base#push_open_ticket_screen makes for the old UI: which view an agent
#   who picked up the call lands on.
class Service::Cti::Log::ResolvePickupTarget < Service::Base
  attr_reader :log

  def initialize(log:)
    @log = log
  end

  def execute
    {
      view:,
      customer:,
      log:,
    }
  end

  private

  def view
    return :ticket_create if !customer
    return :ticket_create if !recent_ticket?

    :user_detail
  end

  # Memoized with defined?, since no detected customer is a valid result.
  def customer
    return @customer if defined?(@customer)

    @customer = ::User.find_by(id: log.best_customer_id_of_log_entry)
  end

  def recent_ticket?
    last_activity = Setting.get('cti_customer_last_activity')

    ::Ticket.where(customer_id: customer.id).exists?(['updated_at > ?', last_activity.seconds.ago])
  end
end
