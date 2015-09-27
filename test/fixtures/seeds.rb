# encoding: utf-8
# inital data set as extention to db/seeds.rb
email_address = EmailAddress.create_if_not_exists(
  id: 1,
  realname: 'Zammad',
  email: 'zammad@localhost',
  updated_by_id: 1,
  created_by_id: 1
)
Group.all.each {|group|
  group.email_address_id = email_address.id
  group.save
}
