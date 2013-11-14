# encoding: utf-8
require 'test_helper'
 
class EmailProcessTest < ActiveSupport::TestCase
  test 'process' do
    files = [
      {
        :data => 'From: me@example.com
To: customer@example.com
Subject: some subject

Some Text',
        :success => true,
      },
      {
        :data => 'From: me@example.com
To: customer@example.com
Subject: some subject
X-Zammad-Ignore: true

Some Text',
        :success => false,
      },
      {
        :data => 'From: me@example.com
To: customer@example.com
Subject: some subject
X-Zammad-Priority: 3 high
X-Zammad-Article-Sender: system
x-Zammad-Article-Type: phone

Some Text',
        :success => true,
        :result => {
          0 => {
            :ticket_priority       => '3 high',
            :title                 => 'some subject',
          },
          1 => {
            :ticket_article_sender => 'System',
            :ticket_article_type   => 'phone',
          },
        },
      },
      {
        :data => "From: me@example.com
To: customer@example.com
Subject: äöü some subject

Some Textäöü",
        :success => true,
        :result => {
          0 => {
            :ticket_priority       => '2 normal',
            :title                 => 'äöü some subject',
          },
          1 => {
            :body                  => 'Some Textäöü',
            :ticket_article_sender => 'Customer',
            :ticket_article_type   => 'email',
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
            :ticket_priority       => '2 normal',
            :title                 => '', # should be äöü some subject, but can not be parsed from mime tools
          },
          1 => {
            :body                  => 'Some Textäöü',
            :ticket_article_sender => 'Customer',
            :ticket_article_type   => 'email',
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
        :success => true,
        :result => {
          0 => {
            :ticket_priority       => '2 normal',
            :title                 => '【专业为您注册香港及海外公司（好处多多）】　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　',
          },
          1 => {
            :body                  => 'Some Text',
            :ticket_article_sender => 'Customer',
            :ticket_article_type   => 'email',
          },
        },
      },
    ]

    files.each { |file|
      parser = Channel::EmailParser.new
      result = parser.process( { :trusted => true }, file[:data] )
      if file[:success] && result[1]
        assert( true )
        if file[:result]
          [ 0, 1, 2 ].each { |level|
            if file[:result][level]
              file[:result][level].each { |key, value|
                if result[level].send(key).respond_to?('name')
                  assert_equal( result[level].send(key).name, value.to_s)
                else
                  assert_equal( result[level].send(key), value.to_s)
                end
              }
            end
          }
        end
      elsif !file[:success] && result == true
        assert( true )
      elsif !file[:success] && result[1]
        assert( false, 'ticket should not be created' )
      else
        assert( false, 'UNKNOWN!' )
      end
    }
  end
end
