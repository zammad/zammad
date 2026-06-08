# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class TicketOverviewQueryPollingIntervalRanges < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'ui_ticket_overview_query_polling')
    return if setting.nil?

    insert_interval_ranges(setting)
  end

  private

  def insert_interval_ranges(setting) # rubocop:disable Metrics/AbcSize
    value = setting.state_current['value'] || {}
    background = value['background'] || {}
    background['interval_ranges'] = [
      {
        threshold_sec: 1.hour.to_i,
        interval_sec:  15.seconds.to_i,
        cache_ttl_sec: 15.seconds.to_i,
      },
      {
        threshold_sec: 2.hours.to_i,
        interval_sec:  20.seconds.to_i,
        cache_ttl_sec: 20.seconds.to_i,
      },
      {
        threshold_sec: 4.hours.to_i,
        interval_sec:  30.seconds.to_i,
        cache_ttl_sec: 30.seconds.to_i,
      },
      {
        threshold_sec: 12.hours.to_i,
        interval_sec:  45.seconds.to_i,
        cache_ttl_sec: 45.seconds.to_i,
      },
      {
        threshold_sec: 1.day.to_i,
        interval_sec:  1.minute.to_i,
        cache_ttl_sec: 1.minute.to_i,
      },
      {
        threshold_sec: 3.days.to_i,
        interval_sec:  2.minutes.to_i,
        cache_ttl_sec: 2.minutes.to_i,
      },
      {
        threshold_sec: 1.week.to_i,
        interval_sec:  3.minutes.to_i,
        cache_ttl_sec: 3.minutes.to_i,
      },
    ]

    new_state = value.merge('background' => background)

    setting.update!(
      state_current: { value: new_state },
      state_initial: { value: new_state },
    )
  end
end
