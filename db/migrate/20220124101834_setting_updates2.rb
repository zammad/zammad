# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class SettingUpdates2 < ActiveRecord::Migration[6.0]
  def change # rubocop:disable Metrics/AbcSize

    return if !Setting.exists?(name: 'system_init_done')

    settings_update = [
      {
        title:       'Ticket Last Contact Behaviour',
        name:        'ticket_last_contact_behaviour',
        description: 'Defines how the last customer contact time of tickets should be calculated.',
        options:     {
          form: [
            {
              display:   '',
              null:      true,
              name:      'ticket_last_contact_behaviour',
              tag:       'select',
              translate: true,
              options:   {
                'based_on_customer_reaction'     => 'Use the time of the very last customer article.',
                'check_if_agent_already_replied' => 'Use the start time of the last customer thread (which may consist of multiple articles).',
              },
            },
          ],
        },
      },
      {
        title:       'Sender based on Reply-To header',
        name:        'postmaster_sender_based_on_reply_to',
        description: 'Set/overwrite sender/from of email based on "Reply-To" header. Useful to set correct customer if email is received from a third-party system on behalf of a customer.',
        options:     {
          form: [
            {
              display: '',
              null:    true,
              name:    'postmaster_sender_based_on_reply_to',
              tag:     'select',
              options: {
                ''                                     => '-',
                'as_sender_of_email'                   => 'Take Reply-To header as sender/from of email.',
                'as_sender_of_email_use_from_realname' => 'Take Reply-To header as sender/from of email and use the real name of origin from.',
              },
            },
          ],
        },
      },
    ]

    settings_update.each do |setting|
      fetched_setting = Setting.find_by(name: setting[:name])
      next if !fetched_setting

      if setting[:title]
        # "Updating title of #{setting[:name]} to #{setting[:title]}"
        fetched_setting.title = setting[:title]
      end

      if setting[:description]
        # "Updating description of #{setting[:name]} to #{setting[:description]}"
        fetched_setting.description = setting[:description]
      end

      if setting[:options]
        # "Updating description of #{setting[:name]} to #{setting[:description]}"
        fetched_setting.options = setting[:options]
      end

      fetched_setting.save!
    end
  end
end
