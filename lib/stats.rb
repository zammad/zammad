# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Stats

=begin

generate stats for user

  Stats.generate

returns

  result = true # if generation was successfully

=end

  def self.generate

    # generate stats per agent
    users = User.with_permissions('ticket.agent')
    agent_count = 0
    user_result = {}
    users.each do |user|
      next if user.id == 1
      next if !user.active

      agent_count += 1
      data = {}

      backends = Setting.where(area: 'Dashboard::Stats')
      if backends.blank?
        raise "No settings with area 'Dashboard::Stats' defined"
      end

      backends.each do |stats_item|
        # additional permission check
        next if stats_item.preferences[:permission] && !user.permissions?(stats_item.preferences[:permission])

        backend = stats_item.state_current[:value]
        if !backend
          raise "Dashboard::Stats backend #{stats_item.name} is not defined"
        end

        require_dependency backend.to_filename
        backend = backend.constantize

        data[backend] = backend.generate(user)
      end
      user_result[user] = data
    end

    # calculate average
    backend_average_sum = {}
    user_result.each_value do |data|
      data.each do |backend_model, backend_result|
        next if !backend_result.key?(:used_for_average)

        if !backend_average_sum[backend_model]
          backend_average_sum[backend_model] = 0
        end
        backend_average_sum[backend_model] += backend_result[:used_for_average]
      end
    end

    # generate average param and icon state
    backend_average_sum.each do |backend_model_average, result|
      average = ( result.to_f / agent_count ).round(1)
      user_result.each do |user, data|
        next if !data[backend_model_average]
        next if !data[backend_model_average].key?(:used_for_average)

        data[backend_model_average][:average_per_agent] = average

        # generate icon state
        backend_model_average.to_s.constantize.average_state(data[backend_model_average], user.id)
      end
    end

    user_result.each do |user, data|
      data_for_user = {}
      data.each do |backend, result|
        data_for_user[backend.to_app_model] = result
      end
      state_store = StatsStore.sync(
        stats_storable: user,
        key:            'dashboard',
        data:           data_for_user,
      )

      message = {
        event: 'resetCollection',
        data:  {
          state_store.class.to_app_model => [state_store],
        },
      }
      Sessions.send_to(user.id, message)
      event = {
        event: 'dashboard_stats_rebuild',
      }
      Sessions.send_to(user.id, event)
    end

    true
  end

end
