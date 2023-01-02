# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module MonitoringHelper
  class AmountCheck
    CHECKS_MAP = [
      { param: :max_critical, notice: 'critical', type: 'gt' },
      { param: :min_critical, notice: 'critical', type: 'lt' },
      { param: :max_warning, notice: 'warning', type: 'gt' },
      { param: :min_warning, notice: 'warning', type: 'lt' },
    ].freeze

    TIMESCALE_MAP = {
      's' => :seconds,
      'm' => :minutes,
      'h' => :hours,
      'd' => :days
    }.freeze

    attr_reader :params

    def initialize(params)
      @params = params
    end

    def check_amount
      if given_params.blank?
        return {
          count: ticket_count
        }
      end

      if (failed_message = given_params.lazy.map { |row, value| check_single_row(row, value) }.find(&:present?))
        return failed_message
      end

      {
        state: 'ok',
        count: ticket_count,
      }
    end

    private

    def given_periode
      params[:periode]
    end

    def given_params
      CHECKS_MAP.filter_map do |row|
        next if params[row[:param]].blank?

        value = params[row[:param]].to_i
        raise Exceptions::UnprocessableEntity, "#{row[:param]} needs to be an integer!" if value.zero?

        [row, value]
      end
    end

    def created_at_threshold
      raise Exceptions::UnprocessableEntity, 'periode is missing!' if given_periode.blank?

      timescale = TIMESCALE_MAP[ given_periode.last ]
      raise Exceptions::UnprocessableEntity, 'periode needs to have s, m, h or d as last!' if !timescale

      periode = given_periode.first.to_i
      raise Exceptions::UnprocessableEntity, 'periode needs to be an integer!' if periode.zero?

      periode.send(timescale).ago
    end

    def ticket_count
      @ticket_count ||= Ticket.where('created_at >= ?', created_at_threshold).count
    end

    def check_single_row(row, value)
      message = case row[:type]
                when 'gt'
                  if ticket_count > value
                    "The limit of #{value} was exceeded with #{ticket_count} in the last #{given_periode}"
                  end
                when 'lt'
                  if ticket_count <= value
                    "The minimum of #{value} was undercut by #{ticket_count} in the last #{given_periode}"
                  end
                end

      return if !message

      {
        state:   row[:notice],
        message: message,
        count:   ticket_count,
      }
    end
  end
end
