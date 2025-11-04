# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

org_community = Organization.create_if_not_exists(
  id:   1,
  name: __('Zammad Foundation'),
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

if Ticket.none?
  ticket = Ticket.create!(
    group_id:    Group.find_by(name: 'Users').id,
    customer_id: User.find_by(login: 'nicole.braun@zammad.org').id,
    title:       __('Help me! I am an example ticket 🎓'),
  )
  Ticket::Article.create!(
    ticket_id:    ticket.id,
    type_id:      Ticket::Article::Type.find_by(name: 'phone').id,
    sender_id:    Ticket::Article::Sender.find_by(name: 'Customer').id,
    content_type: 'text/html',
    from:         'Zammad Feedback <feedback@zammad.org>',
    body:         '<p>Hi, I\'m Nicole Braun,</p>
<p>I\'m an example user here to show you what a ticket can look like.</p>
<p>A ticket displays the full conversation of a request, made up of articles. Articles are messages or notes shown in tickets like this one. You can reply and add any information needed to help close the request.</p>
<p>Explore these links for more insight into Zammad:</p>
<ul>
<li><a href="https://admin-docs.zammad.org/en/latest" target="_blank">Zammad Admin Documentation</a></li>
<li><a href="https://user-docs.zammad.org/en/latest" target="_blank">Zammad User Documentation</a></li>
<li><a href="https://support.zammad.com/help" target="_blank">Zammad Knowledge Base</a></li>
</ul>
<p>Feel free to use this ticket to explore and get comfortable with Zammad.</p>
<p>You can even reply to me—I\'m looking forward to hearing from you. 👋</p>
<p>And don\'t forget, our friendly team is always <a href="https://zammad.com/en/company/contact" target="_blank">happy to help</a> with any questions.</p>
<p>Have fun! 🚀<br>Nicole Braun</p>',
    internal:     false,
  )

  ticket.tag_add(__('Example tag'))

end

UserInfo.current_user_id = 1
