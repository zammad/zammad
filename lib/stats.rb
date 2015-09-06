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

    users = User.of_role('Agent')
    users.each {|user|
      next if user.id == 1
      data = {}
      backends.each {|backend|
        data[backend.to_app_model] = backend.generate(user)
      }
      StatsStore.sync(
        object: 'User',
        o_id: user.id,
        key: 'dashboard',
        data: data,
      )
    }
    true
  end

end
