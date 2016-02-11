# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class FirstStepsController < ApplicationController
  before_action :authentication_check

  def index
    result = []
    if !current_user.role?(%w(Agent Admin))
      render json: result
      return
    end

    invite_agents = false
    #if User.of_role('Agent').count > 2
    #  invite_agents = true
    #end
    invite_customers = false
    #if User.of_role('Customer').count > 2
    #  invite_customers = true
    #end

    chat_active = false
    if Setting.get('chat')
      chat_active = true
    end
    from_active = false
    if Setting.get('form_ticket_create')
      from_active = true
    end
    twitter_active = false
    if Channel.where(area: 'Twitter::Account').count > 0
      twitter_active = true
    end
    facebook_active = false
    if Channel.where(area: 'Facebook::Account').count > 0
      facebook_active = true
    end
    email_active = false
    if Channel.where(area: 'Email::Account').count > 0
      email_active = true
    end
    text_module_active = false
    if TextModule.count > 0
      text_module_active = true
    end
    macro_active = false
    if Macro.count > 1
      macro_active = true
    end

    if current_user.role?('Admin')

      result = [
        {
          name: 'Configuration',
          items: [
            {
              name: 'Branding',
              checked: true,
              location: '#settings/branding',
            },
            {
              name: 'Your Email Configuration',
              checked: email_active,
              location: '#channels/email',
            },
            {
              name: 'Invite Agents/Colleges to help working on Tickets',
              checked: invite_agents,
              location: '#invite_agent',
            },
            {
              name: 'Invite Customers to create issues in Zammad',
              checked: invite_customers,
              location: '#invite_customer',
            },
          ],
        },
        {
          name: 'How to use it',
          items: [
            {
              name: 'Intro',
              checked: true,
              location: '#clues',
            },
            {
              name: 'Create a Test Ticket',
              checked: false,
              location: '#create_test_ticket',
            },
            {
              name: 'Create Overviews',
              checked: false,
              location: '#manage/overviews',
            },
            {
              name: 'Create Text Modues',
              checked: text_module_active,
              location: '#manage/text_modules',
            },
            {
              name: 'Create Macros',
              checked: macro_active,
              location: '#manage/macros',
            },
          ],
        },
        {
          name: 'Additionals Channels',
          items: [
            {
              name: 'Twitter',
              checked: twitter_active,
              location: '#channels/twitter',
            },
            {
              name: 'Facebook',
              checked: facebook_active,
              location: '#channels/facebook',
            },
            {
              name: 'Chat',
              checked: chat_active,
              location: '#channels/chat',
            },
            {
              name: 'Online Forms',
              checked: from_active,
              location: '#channels/form',
            },
          ],
        },
      ]

      render json: result
      return
    end

    result = [
      {
        name: 'How to use it',
        items: [
          {
            name: 'Intro',
            checked: true,
            location: '#clues',
          },
          {
            name: 'Create a Test Ticket',
            checked: false,
            location: '#create_test_ticket',
          },
          {
            name: 'Invite Customers to create issues in Zammad',
            checked: invite_customers,
            location: '#invite_customer',
          },
        ],
      },
    ]

    render json: result
  end

end
