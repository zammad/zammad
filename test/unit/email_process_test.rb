# encoding: utf-8
require 'test_helper'

class EmailProcessTest < ActiveSupport::TestCase
  test 'process simple' do
    files = [
      {
        :data => 'From: me@example.com
To: customer@example.com
Subject: some subject

Some Text',
        :trusted => false,
        :success => true,
      },
      {
        :data => "From: me@example.com
To: customer@example.com
Subject: äöü some subject

Some Textäöü",
        :trusted => false,
        :success => true,
        :result => {
          0 => {
            :priority => '2 normal',
            :title    => 'äöü some subject',
          },
          1 => {
            :body     => 'Some Textäöü',
            :sender   => 'Customer',
            :type     => 'email',
            :internal => false,
          },
        },
      },
      {
        :data => "From: me@example.com
To: customer@example.com
Subject: äöü some subject

Some Textäöü".encode("ISO-8859-1"),
        :success => true,
        :result => {
          0 => {
            :priority   => '2 normal',
            :title      => '', # should be äöü some subject, but can not be parsed from mime tools
          },
          1 => {
            :body       => 'Some Textäöü',
            :sender     => 'Customer',
            :type       => 'email',
            :internal   => false,
          },
        },
      },
      {
        :data => "From: me@example.com
To: customer@example.com
Subject: Subject: =?utf-8?B?44CQ5LiT5Lia5Li65oKo5rOo5YaM6aaZ5riv5Y+K5rW35aSW5YWs5Y+477yI5aW95aSE5aSa5aSa77yJ?=
        =?utf-8?B?44CR44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA5Lq654mpICAgICAgICAgIA==?=
        =?utf-8?B?ICAgICAgICAgIOS6kuiBlOe9keS6i+eZvuW6puaWsOmXu+eLrOWutg==?=
        =?utf-8?B?5Ye65ZOB5Lyg5aqS5o2i5LiA5om55o235YWL5oi057u05pav5p2v5Yaz6LWb5YmN5Lu75ZG95Li05pe2?=
        =?utf-8?B?6aKG6ZifIOWJjemihumYn+WboOeXheS9j+mZouacgOaWsDrnm5bkuJbmsb3ovaborq8gMQ==?=
        =?utf-8?B?MeaciDbml6XvvIzpgJrnlKjmsb3ovablrqPluIPku4rlubQxMOaciOS7veWcqOWNjumUgA==?=
        =?utf-8?B?6YePLi4u5YeP5oyB5LiJ54m557Si6YGTIOWtn+WHr+WwhuWFqOWKm+WPkeWxlea5mOmEgg==?=
        =?utf-8?B?5oOF5rGf6Z2S5pGE5b2x5L2c5ZOB56eR5oqA5pel5oql6K6vIO+8iOiusOiAhei/h+WbveW/oCA=?=
        =?utf-8?B?6YCa6K6v5ZGY6ZmI6aOe54eV77yJ5rGf6IuP55yB5peg57q/55S156eR5a2m56CU56m25omA5pyJ6ZmQ?=
        =?utf-8?B?5YWs5Y+46Zmi5aOr5bel5L2c56uZ5pel5YmN5q2j5byP5bu6Li4uW+ivpue7hl0=?=

Some Text",
        :trusted => false,
        :success => true,
        :result => {
          0 => {
            :priority   => '2 normal',
            :title      => '【专业为您注册香港及海外公司（好处多多）】　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　',
          },
          1 => {
            :body       => 'Some Text',
            :sender     => 'Customer',
            :type       => 'email',
          },
        },
      },
    ]
    process(files)
  end
  test 'process trusted' do
    files = [
      {
        :data => 'From: me@example.com
To: customer@example.com
Subject: some subject
X-Zammad-Ignore: true

Some Text',
        :trusted => true,
        :success => false,
      },
      {
        :data => 'From: me@example.com
To: customer@example.com
Subject: some subject
X-Zammad-Ticket-priority: 3 high
X-Zammad-Article-sender: System
x-Zammad-Article-type: phone
x-Zammad-Article-Internal: true

Some Text',
        :trusted => true,
        :success => true,
        :result => {
          0 => {
            :priority     => '3 high',
            :title        => 'some subject',
          },
          1 => {
            :sender       => 'System',
            :type         => 'phone',
            :internal     => true,
          },
        },
      },
    ]
    process(files)
  end

  test 'process not trusted' do
    files = [
      {
        :data => 'From: me@example.com
To: customer@example.com
Subject: some subject
X-Zammad-Ticket-Priority: 3 high
X-Zammad-Article-Sender: System
x-Zammad-Article-Type: phone
x-Zammad-Article-Internal: true

Some Text',
        :trusted => false,
        :success => true,
        :result => {
          0 => {
            :priority     => '2 normal',
            :title        => 'some subject',
          },
          1 => {
            :sender       => 'Customer',
            :type         => 'email',
            :internal     => false,
          },
        },
      },
    ]
    process(files)
  end

  test 'process with postmaster filter' do
    group = Group.create_if_not_exists(
      :name          => 'Test Group',
      :created_by_id => 1,
      :updated_by_id => 1,
    )
    PostmasterFilter.destroy_all
    PostmasterFilter.create(
      :name => 'not used',
      :match => {
        :from => 'nobody@example.com',
      },
      :perform => {
        'X-Zammad-Ticket-priority' => '3 high',
      },
      :channel       => 'email',
      :active        => true,
      :created_by_id => 1,
      :updated_by_id => 1,
    )
    PostmasterFilter.create(
      :name => 'used',
      :match => {
        :from => 'me@example.com',
      },
      :perform => {
        'X-Zammad-Ticket-group_id' => group.id,
        'x-Zammad-Article-Internal' => true,
      },
      :channel       => 'email',
      :active        => true,
      :created_by_id => 1,
      :updated_by_id => 1,
    )
    PostmasterFilter.create(
      :name => 'used x-any-recipient',
      :match => {
        'x-any-recipient' => 'any@example.com',
      },
      :perform => {
        'X-Zammad-Ticket-group_id' => 2,
        'x-Zammad-Article-Internal' => true,
      },
      :channel       => 'email',
      :active        => true,
      :created_by_id => 1,
      :updated_by_id => 1,
    )
    files = [
      {
        :data => 'From: me@example.com
To: customer@example.com
Subject: some subject

Some Text',
        :trusted => false,
        :success => true,
        :result => {
          0 => {
            :group        => group.name,
            :priority     => '2 normal',
            :title        => 'some subject',
          },
          1 => {
            :sender       => 'Customer',
            :type         => 'email',
            :internal     => true,
          },
        },
      },
      {
        :data => 'From: somebody@example.com
To: bod@example.com
Cc: any@example.com
Subject: some subject

Some Text',
        :trusted => false,
        :success => true,
        :result => {
          0 => {
            :group          => 'Twitter',
            :priority       => '2 normal',
            :title          => 'some subject',
          },
          1 => {
            :sender         => 'Customer',
            :type           => 'email',
            :internal       => true,
          },
        },
      },
    ]
    process(files)
    PostmasterFilter.destroy_all
  end

  def process(files)
    files.each { |file|
      parser = Channel::EmailParser.new
      result = parser.process( { :trusted => file[:trusted] }, file[:data] )
      if file[:success]
        if result && result.class == Array && result[1]
          assert( true )
          if file[:result]
            [ 0, 1, 2 ].each { |level|
              if file[:result][level]
                file[:result][level].each { |key, value|
                  if result[level].send(key).respond_to?('name')
                    assert_equal( result[level].send(key).name, value.to_s)
                  else
                    assert_equal( result[level].send(key), value)
                  end
                }
              end
            }
          end
        else
          assert( false, 'ticket not created', file )
        end
      elsif !file[:success]
        if result && result.class == Array && result[1]
        puts result.inspect
          assert( false, 'ticket should not be created but is created' )
        else
          assert( true, 'ticket not created - nice' )
        end
      else
        assert( false, 'UNKNOWN!' )
      end
    }
  end
end