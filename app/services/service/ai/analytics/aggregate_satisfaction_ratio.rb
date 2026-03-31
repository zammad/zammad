# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Analytics::AggregateSatisfactionRatio < Service::Base
  attr_reader :triggered_by

  def initialize(triggered_by:)
    @triggered_by = triggered_by

    super()
  end

  def execute
    return if triggered_by.nil?

    counts = build_ratio
    total  = counts[:total]

    {
      positive: {
        count:   counts[:positive],
        percent: percentage(counts[:positive], total),
      },
      negative: {
        count:   counts[:negative],
        percent: percentage(counts[:negative], total),
      },
      neutral:  {
        count:   counts[:neutral],
        percent: percentage(counts[:neutral], total),
      },
      total:    total,
    }
  end

  private

  def percentage(count, total)
    return 0 if total.zero?

    (count.to_f / total * 100).round(2)
  end

  def build_ratio
    scope = AI::Analytics::Usage
      .joins(:ai_analytics_run)
      .where(ai_analytics_runs: { triggered_by: triggered_by })
      .since_reset(triggered_by&.analytics_stats_reset_at)

    scope
      .select(
        Arel.sql(
          <<~SQL.squish
            COUNT(*) FILTER (WHERE rating = TRUE) AS positive,
            COUNT(*) FILTER (WHERE rating = FALSE) AS negative,
            COUNT(*) FILTER (WHERE rating IS NULL) AS neutral,
            COUNT(*) AS total
          SQL
        )
      )
      .take
      .attributes
      .symbolize_keys
      .slice(:positive, :negative, :neutral, :total)
      .transform_values(&:to_i)
  end
end
