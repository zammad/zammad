class SequencerLogLevelSetting < ActiveRecord::Migration[5.1]
  def change

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Sequencer log level',
      name:        'sequencer_log_level',
      area:        'Core',
      description: 'Defines the log levels for various logging actions of the Sequencer.',
      options:     {},
      state:       {
        sequence: {
          start_finish: :debug,
          unit:         :debug,
          result:       :debug,
        },
        state: {
          optional:                 :debug,
          set:                      :debug,
          get:                      :debug,
          attribute_initialization: {
            start_finish: :debug,
            attributes:   :debug,
          },
          parameter_initialization: {
            parameters:   :debug,
            start_finish: :debug,
            unused:       :debug,
          },
          expectations_initialization: :debug,
          cleanup: {
            start_finish: :debug,
            remove:       :debug,
          }
        }
      },
      frontend: false,
    )
  end
end
