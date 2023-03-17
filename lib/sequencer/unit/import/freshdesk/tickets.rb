# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::Tickets < Sequencer::Unit::Import::Freshdesk::SubSequence::Object

  EXPECTING = %i[action response resources].freeze

  private

  def request_params
    {
      page:          page,
      updated_since: updated_since,
      order_by:      'updated_at',
      order_type:    :asc,
    }
  end

  def page
    page_cycle + 1
  end

  def page_cycle
    iteration % 300
  end

  def updated_since
    @updated_since ||= '1970-01-01'

    return @updated_since if !new_page_cycle?

    @updated_since = result[:resources].last['updated_at']
  end

  def skipped_resource_id
    super

    return @skipped_resource_id if !new_page_cycle?

    @skipped_resource_id = result[:resources].last['id']
  end

  def new_page_cycle?
    return false if page_cycle != 0
    return false if iteration.zero?

    true
  end
end
