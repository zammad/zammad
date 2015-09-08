# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

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
    ]

    # generate stats per agent
    users = User.of_role('Agent')
    agent_count = 0
    user_result = {}
    users.each {|user|
      next if user.id == 1
      next if !user.active
      agent_count += 1
      data = {}
      backends.each {|backend|
        data[backend.to_app_model] = backend.generate(user)
      }
      user_result[user.id] = data
    }

    # calculate average
    backend_average_sum = {}
    user_result.each {|user_id, data|
      data.each {|backend_model, backend_result|
        next if !backend_result.has_key?(:used_for_average)
        if !backend_average_sum[backend_model]
          backend_average_sum[backend_model] = 0
        end
        backend_average_sum[backend_model] += backend_result[:used_for_average]
      }
    }

    # generate average stats
    backend_average_sum.each {|backend_model_average, result|
      average = ( result.to_f / agent_count.to_f ).round(1)
      user_result.each {|user_id, data|
        data.each {|backend_model_data, backend_result|
          next if backend_model_data != backend_model_average
          next if !backend_result.has_key?(:used_for_average)
          backend_result[:average_per_agent] = average
        }
      }
    }

    user_result.each {|user_id, data|
      StatsStore.sync(
        object: 'User',
        o_id: user_id,
        key: 'dashboard',
        data: data,
      )
    }

    true
  end

end
