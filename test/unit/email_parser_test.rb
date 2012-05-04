# encoding: utf-8
require 'test_helper'
 
class EmailParserTest < ActiveSupport::TestCase
  test 'parse' do
    files = [
      {
        :data     => IO.read('test/fixtures/mail1.box'),
        :body_md5 => 'fb6ed5070ffbb821b67b15b83239e1db',
        :params   => {
          :from               => 'John.Smith@example.com',
          :from_email         => 'John.Smith@example.com',
          :from_display_name  => nil,
          :subject            => 'CI Daten für PublicView ',
        },
      },
      {
        :data     => IO.read('test/fixtures/mail2.box'),
        :body_md5 => '25a1ff722497271965b55e52659784a6',
        :params   => {
          :from               => 'Martin Edenhofer <martin@example.com>',
          :from_email         => 'martin@example.com',
          :from_display_name  => 'Martin Edenhofer',
          :subject            => 'aaäöüßad asd',
          :plain_part         => "äöüß ad asd\r\n\r\n-Martin\r\n\r\n--\r\nOld programmers never die. They just branch to a new address.",
        },
      },
    ]

    files.each { |file|
 
      parser = Channel::EmailParser.new
      data = parser.parse( file[:data] )
      
      # check body
      md5 = Digest::MD5.hexdigest( data[:plain_part] )
      assert_equal( file[:body_md5], md5 )
      
      # check params
      file[:params].each { |key, value|
        if key.to_s == 'plain_part'
          assert_equal( Digest::MD5.hexdigest( file[:params][key.to_sym].to_s ), Digest::MD5.hexdigest( data[key.to_sym].to_s ) )
        else
          assert_equal( file[:params][key.to_sym], data[key.to_sym] )
        end
      }
    }
  end
end