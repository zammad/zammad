# encoding: utf-8
require 'test_helper'

class NotificationFactoryTest < ActiveSupport::TestCase
  test 'notifications' do
    ticket = Ticket.create(
      :title           => 'some title äöüß',
      :group           => Group.lookup( :name => 'Users'),
      :customer_id     => 2,
      :ticket_state    => Ticket::State.lookup( :name => 'new' ),
      :ticket_priority => Ticket::Priority.lookup( :name => '2 normal' ),
      :updated_by_id   => 1,
      :created_by_id   => 1,
    )

    tests = [
      {
        :locale => 'en',
        :string => 'Hi #{recipient.firstname},',
        :result => 'Hi Nicole,',
      },
      {
        :locale => 'de',
        :string => 'Hi #{recipient.firstname},',
        :result => 'Hi Nicole,',
      },
      {
        :locale => 'de',
        :string => 'Hi #{recipient.firstname}, Group: #{ticket.group.name}',
        :result => 'Hi Nicole, Group: Users',
      },
      {
        :locale => 'de',
        :string => '#{config.http_type} some text',
        :result => 'http some text',
      },
      {
        :locale => 'de',
        :string => 'i18n(#{"New"}) some text',
        :result => 'Neu some text',
      },
      {
        :locale => 'de',
        :string => '\'i18n(#{ticket.ticket_state.name})\' ticket state',
        :result => '\'neu\' ticket state',
      },
    ]
    tests.each { |test|
      result = NotificationFactory.build(
        :string  => test[:string],
        :objects => {
          :ticket    => ticket,
          :recipient => User.find(2),
        },
        :locale  => test[:locale]
      )
      assert_equal( result, test[:result], "verify result" )
    }

    ticket.destroy
  end
end