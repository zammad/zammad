class EmailForwardPrefixSettingIssue1730 < ActiveRecord::Migration[5.1]
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    Setting.create_if_not_exists(
      title: 'Ticket Subject Forward',
      name: 'ticket_subject_fwd',
      area: 'Email::Base',
      description: 'The text at the beginning of the subject in an email forward, e. g. FWD.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'ticket_subject_fwd',
            tag: 'input',
          },
        ],
      },
      state: 'FWD',
      preferences: {
        permission: ['admin.channel_email'],
      },
      frontend: false
    )
  end
end
