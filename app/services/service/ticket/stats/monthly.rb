# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Stats::Monthly < Service::Base
  requires_current_user!

  attr_reader :conditions

  def initialize(conditions:)
    @conditions = conditions
  end

  def execute
    Time.use_zone(Setting.get('timezone_default')) do
      result = TicketPolicy::ReadScope
        .new(current_user)
        .resolve
        .where(conditions)
        .select(selects)
        .take

      result_to_hashes(result)
    end
  end

  private

  def result_to_hashes(result)
    dates.map do |date|
      {
        month_number:    date.month,
        year:            date.year,
        month_label:     Date::ABBR_MONTHNAMES[date.month],
        tickets_created: result[count_key(date, 'created_at')],
        tickets_closed:  result[count_key(date, 'close_at')],
      }
    end
  end

  def count_key(date, type)
    "count_#{type}_#{date.month}_#{date.year}"
  end

  def dates
    @dates ||= (0..11).map { it.months.ago }
  end

  def selects
    @selects ||= dates.map do |date|
      date_start = date.beginning_of_month
      date_end   = date.end_of_month

      [
        count_with_filter('created_at', date),
        count_with_filter('close_at', date),
      ].map { ActiveRecord::Base.sanitize_sql_array([it, { date_start:, date_end: }]) }
    end
      .flatten
      .join(', ')
  end

  def count_with_filter(attr, date)
    "COUNT(*) FILTER (WHERE #{attr} BETWEEN :date_start AND :date_end) AS #{count_key(date, attr)}"
  end
end
