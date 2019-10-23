org_community = Organization.create_if_not_exists(
  id:   1,
  name: 'VIAcode',
)
user_community = User.create_or_update(
  id:              2,
  login:           'sales@viacode.com',
  firstname:       'VIAcode',
  lastname:        'Sales',
  email:           'sales@viacode.com',
  password:        '',
  active:          true,
  roles:           [ Role.find_by(name: 'Customer') ],
  organization_id: org_community.id,
)

UserInfo.current_user_id = user_community.id

if Ticket.count.zero?
  ticket = Ticket.create!(
    group_id:    Group.find_by(name: 'Users').id,
    customer_id: User.find_by(login: 'sales@viacode.com').id,
    title:       'Welcome to VIAcode Incident Management System for Azure!',
  )
  Ticket::Article.create!(
    ticket_id: ticket.id,
    type_id:   Ticket::Article::Type.find_by(name: 'phone').id,
    sender_id: Ticket::Article::Sender.find_by(name: 'Customer').id,
    from:      'VIAcode Sales <sales@viacode.com>',
    body:      'Welcome!

    Thank you for choosing VIAcode Incident Management System for Azure.

  Let VIAcode deal with these alerts & manage your Azure cloud operation for free; [activate here](https://www.viacode.com/services/azure-managed-services/?utm_source=product&utm_medium=email&utm_campaign=VIMS&utm_content=passwordchangeemail)
  ',
    internal:  false,
  )
end

UserInfo.current_user_id = 1
