# encoding: utf-8
# inital data set as extention to db/seeds.rb

Trigger.destroy_all
Job.destroy_all

# create email address and apply it to all groups
channel_id = nil
channel = Channel.find_by(area: 'Email::Notification', active: true)
if channel
  channel_id = channel.id
end

email_address = EmailAddress.create_or_update(
  realname: 'Zammad',
  email: 'zammad@localhost',
  channel_id: channel_id,
  updated_by_id: 1,
  created_by_id: 1
)
Group.all.each { |group|
  group.email_address_id = email_address.id
  group.save
}
