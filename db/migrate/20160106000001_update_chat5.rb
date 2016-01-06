class UpdateChat5 < ActiveRecord::Migration
  def change

    Setting.create_if_not_exists(
      title: 'Agent idle timeout',
      name: 'chat_agent_idle_timeout',
      area: 'Chat::Extended',
      description: 'Idle timeout in seconds till agent is set offline automatically.',
      options: {
        form: [
          {
            display: '',
            null: false,
            name: 'chat_agent_idle_timeout',
            tag: 'input',
          },
        ],
      },
      preferences: {},
      state: '120',
      frontend: true
    )

  end
end
