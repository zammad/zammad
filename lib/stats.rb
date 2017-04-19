# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

require 'stats_store'

class Stats

=begin

generate stats for user

  Stats.generate

returns

  result = true # if generation was successfully

=end

  def self.generate

    backends = [
      Stats::TicketChannelDistribution,
      Stats::TicketInProcess,
      Stats::TicketLoadMeasure,
      Stats::TicketEscalation,
      Stats::TicketReopen,
      Stats::TicketWaitingTime,
    ]

    # generate stats per agent
    users = User.with_permissions('ticket.agent')
    agent_count = 0
    user_result = {}
    users.each { |user|
      next if user.id == 1
      next if !user.active
      agent_count += 1
      data = {}
      backends.each { |backend|
        data[backend] = backend.generate(user)
      }
      user_result[user.id] = data
    }

    # calculate average
    backend_average_sum = {}
    user_result.each { |_user_id, data|
      data.each { |backend_model, backend_result|
        next if !backend_result.key?(:used_for_average)
        if !backend_average_sum[backend_model]
          backend_average_sum[backend_model] = 0
        end
        backend_average_sum[backend_model] += backend_result[:used_for_average]
      }
    }

    # generate average param and icon state
    backend_average_sum.each { |backend_model_average, result|
      average = ( result.to_f / agent_count.to_f ).round(1)
      user_result.each { |user_id, data|
        next if !data[backend_model_average]
        next if !data[backend_model_average].key?(:used_for_average)
        data[backend_model_average][:average_per_agent] = average

        # generate icon state
        backend_model_average.to_s.constantize.average_state(data[backend_model_average], user_id)
      }
    }

    user_result.each { |user_id, data|
      data_for_user = {}
      data.each { |backend, result|
        data_for_user[backend.to_app_model] = result
      }
      state_store = StatsStore.sync(
        object: 'User',
        o_id: user_id,
        key: 'dashboard',
        data: data_for_user,
      )

      message = {
        event: 'resetCollection',
        data: {
          state_store.class.to_app_model => [state_store],
        },
      }
      Sessions.send_to(user_id, message)
      event = {
        event: 'dashboard_stats_rebuild',
      }
      Sessions.send_to(user_id, event)
    }

    true
  end

end
