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
    ]

    files.each { |file|
 
      parser = Channel::EmailParser.new
      data = parser.parse( file[:data] )
      
      # create md5 of body
      md5 = Digest::MD5.hexdigest( data[:plain_part] )
      assert_equal( file[:body_md5], md5 )      
      file[:params].each { |key, value|
        assert_equal( file[:params][key.to_sym], data[key.to_sym] )      
      }
    }
  end
end