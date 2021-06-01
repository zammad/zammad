# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ReplyToSenderFeature < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Sender based on Reply-To header',
      name:        'postmaster_sender_based_on_reply_to',
      area:        'Email::Base',
      description: 'Set/overwrite sender/from of email based on reply-to header. Useful to set correct customer if email is received from a third party system on behalf of a customer.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'postmaster_sender_based_on_reply_to',
            tag:     'select',
            options: {
              ''                                     => '-',
              'as_sender_of_email'                   => 'Take reply-to header as sender/from of email.',
              'as_sender_of_email_use_from_realname' => 'Take reply-to header as sender/from of email and use realname of origin from.',
            },
          },
        ],
      },
      state:       '',
      preferences: {
        permission: ['admin.channel_email'],
      },
      frontend:    false
    )

    Setting.create_if_not_exists(
      title:       'Defines postmaster filter.',
      name:        '0011_postmaster_sender_based_on_reply_to',
      area:        'Postmaster::PreFilter',
      description: 'Defines postmaster filter to set the sender/from of emails based on reply-to header.',
      options:     {},
      state:       'Channel::Filter::ReplyToBasedSender',
      frontend:    false
    )
  end

end
