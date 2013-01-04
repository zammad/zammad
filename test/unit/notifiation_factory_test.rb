# encoding: utf-8
require 'test_helper'
 
class NotificationFactoryTest < ActiveSupport::TestCase
  test 'notifications' do
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
          :ticket    => Ticket.find(1),
          :recipient => User.find(2),
        },
        :locale  => test[:locale]
      )
      assert_equal( result, test[:result], "verify result" )
    }
  end
end