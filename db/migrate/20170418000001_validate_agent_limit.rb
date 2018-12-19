class ValidateAgentLimit < ActiveRecord::Migration[4.2]
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Set limit of agents',
      name:        'system_agent_limit',
      area:        'Core::Online',
      description: 'Defines the limit of the agents.',
      options:     {},
      state:       false,
      preferences: { online_service_disable: true },
      frontend:    false
    )
  end
end
