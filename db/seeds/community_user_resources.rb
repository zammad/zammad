# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

org_community = Organization.create_if_not_exists(
  id:   1,
  name: 'Zammad Foundation',
)
user_community = User.create_or_update(
  id:              2,
  login:           'nicole.braun@zammad.org',
  firstname:       'Nicole',
  lastname:        'Braun',
  email:           'nicole.braun@zammad.org',
  password:        '',
  active:          true,
  roles:           [ Role.find_by(name: 'Customer') ],
  organization_id: org_community.id,
)

UserInfo.current_user_id = user_community.id

if Ticket.count.zero?
  ticket = Ticket.create!(
    group_id:    Group.find_by(name: 'Users').id,
    customer_id: User.find_by(login: 'nicole.braun@zammad.org').id,
    title:       'Welcome to Zammad!',
  )
  Ticket::Article.create!(
    ticket_id: ticket.id,
    type_id:   Ticket::Article::Type.find_by(name: 'phone').id,
    sender_id: Ticket::Article::Sender.find_by(name: 'Customer').id,
    from:      'Zammad Feedback <feedback@zammad.org>',
    body:      'Welcome!

  Thank you for choosing Zammad.

  You will find updates and patches at https://zammad.org/. Online
  documentation is available at https://zammad.org/documentation. Get
  involved (discussions, contributing, ...) at https://zammad.org/participate.

  Regards,

  Your Zammad Team
  ',
    internal:  false,
  )
end

UserInfo.current_user_id = 1
