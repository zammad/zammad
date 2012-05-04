# encoding: utf-8
require 'test_helper'
 
class StoreTest < ActiveSupport::TestCase
  test 'store attachment' do
    files = [
      {
        :data        => 'hello world',
        :filename    => 'test.txt',
      },
      {
        :data        => 'hello world äöüß',
        :filename    => 'testäöüß.txt',
      },
      {
        :data        => IO.read('test/fixtures/test1.pdf'),
        :filename    => 'test.pdf',
      },      
    ]
    

    files.each { |file|
      
      md5 = Digest::MD5.hexdigest( file[:data] )

      # add attachments
      store = Store.add(
        :object      => 'Test',
        :o_id        => 1,
        :data        => file[:data],
        :filename    => file[:filename],
        :preferences => {}
      )
      assert store

      # get list of attachments
      attachments = Store.list(
        :object => 'Test',
        :o_id   => 1
      )
      assert attachments
  
      # md5 check
      md5_new = Digest::MD5.hexdigest( attachments[0].store_file.data )
      assert_equal( md5, md5_new )

      # filename check
      assert_equal( file[:filename], attachments[0].filename )

      # delete attachments
      success = Store.remove(
        :object => 'Test',
        :o_id   => 1
      )
      assert success
    }    
  end
end

