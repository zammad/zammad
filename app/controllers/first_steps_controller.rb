# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class FirstStepsController < ApplicationController
  prepend_before_action :authentication_check

  before_action -> { render json: [] }, if: -> { !authorized? }

  def index
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
    form_active = false
    if Setting.get('form_ticket_create')
      form_active = true
    end
    twitter_active = false
    if Channel.where(area: 'Twitter::Account').count.positive?
      twitter_active = true
    end
    facebook_active = false
    if Channel.where(area: 'Facebook::Account').count.positive?
      facebook_active = true
    end
    email_active = false
    if Channel.where(area: 'Email::Account').count.positive?
      email_active = true
    end
    text_module_active = false
    if TextModule.count.positive?
      text_module_active = true
    end
    macro_active = false
    if Macro.count > 1
      macro_active = true
    end

    if current_user.permissions?('admin')

      result = [
        {
          name:  'Configuration',
          items: [
            {
              name:     'Branding',
              checked:  true,
              location: '#settings/branding',
            },
            {
              name:     'Your Email Configuration',
              checked:  email_active,
              location: '#channels/email',
            },
            {
              name:     'Invite agents/colleagues to help working on tickets',
              checked:  invite_agents,
              location: '#',
              class:    'js-inviteAgent',
            },
            {
              name:     'Invite customers to create issues in Zammad',
              checked:  invite_customers,
              location: '#',
              class:    'js-inviteCustomer',
            },
          ],
        },
        {
          name:  'How to use it',
          items: [
            {
              name:     'Intro',
              checked:  true,
              location: '#clues',
            },
            {
              name:     'Create a Test Ticket',
              checked:  false,
              location: '#',
              class:    'js-testTicket',
            },
            {
              name:     'Create Text Modules',
              checked:  text_module_active,
              location: '#manage/text_modules',
            },
            {
              name:     'Create Macros',
              checked:  macro_active,
              location: '#manage/macros',
            },
            #{
            #  name: 'Create Overviews',
            #  checked: false,
            #  location: '#manage/overviews',
            #},
          ],
        },
        {
          name:  'Additional Channels',
          items: [
            {
              name:     'Twitter',
              checked:  twitter_active,
              location: '#channels/twitter',
            },
            {
              name:     'Facebook',
              checked:  facebook_active,
              location: '#channels/facebook',
            },
            {
              name:     'Chat',
              checked:  chat_active,
              location: '#channels/chat',
            },
            {
              name:     'Online Forms',
              checked:  form_active,
              location: '#channels/form',
            },
          ],
        },
      ]

      check_availability(result)

      render json: result
      return
    end

    result = [
      {
        name:  'How to use it',
        items: [
          {
            name:     'Intro',
            checked:  true,
            location: '#clues',
          },
          {
            name:     'Create a Test Ticket',
            checked:  false,
            location: '#',
            class:    'js-testTicket',
          },
          {
            name:     'Invite customers to create issues in Zammad',
            checked:  invite_customers,
            location: '#',
            class:    'js-inviteCustomer',
          },
        ],
      },
    ]

    check_availability(result)

    render json: result
  end

  def test_ticket
    agent = current_user
    customer = test_customer
    from = "#{customer.fullname} <#{customer.email}>"
    original_user_id = UserInfo.current_user_id
    result = NotificationFactory::Mailer.template(
      template: 'test_ticket',
      locale:   agent.locale,
      objects:  {
        agent:    agent,
        customer: customer,
      },
      raw:      true,
    )
    UserInfo.current_user_id = customer.id
    ticket = Ticket.create!(
      group_id:    Group.find_by(active: true, name: 'Users').id,
      customer_id: customer.id,
      title:       result[:subject],
    )
    article = Ticket::Article.create!(
      ticket_id:    ticket.id,
      type_id:      Ticket::Article::Type.find_by(name: 'phone').id,
      sender_id:    Ticket::Article::Sender.find_by(name: 'Customer').id,
      from:         from,
      body:         result[:body],
      content_type: 'text/html',
      internal:     false,
    )
    UserInfo.current_user_id = original_user_id
    overview = test_overview
    assets = ticket.assets({})
    assets = article.assets(assets)
    assets = overview.assets(assets)
    render json: {
      overview_id: overview.id,
      ticket_id:   ticket.id,
      assets:      assets,
    }
  end

  private

  def test_overview
    Overview.find_by(name: 'Unassigned & Open')
  end

  def test_customer
    User.find_by(login: 'nicole.braun@zammad.org')
  end

  def check_availability(result)
    return result if test_ticket_active?

    result.each do |item|
      items = []
      item[:items].each do |local_item|
        next if local_item[:name] == 'Create a Test Ticket'

        items.push local_item
      end
      item[:items] = items
    end
    result
  end

  def test_ticket_active?
    overview = test_overview

    return false if !overview
    return false if overview.updated_by_id != 1
    return false if !test_customer
    return false if Group.where(active: true, name: 'Users').count.zero?

    true
  end
end
