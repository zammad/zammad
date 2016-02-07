# encoding: utf-8
require 'test_helper'

class StoreTest < ActiveSupport::TestCase
  test 'store attachment' do
    files = [
      {
        data: 'hello world',
        filename: 'test.txt',
        o_id: 1,
      },
      {
        data: 'hello world äöüß',
        filename: 'testäöüß.txt',
        o_id: 2,
      },
      {
        data: IO.binread('test/fixtures/test1.pdf'),
        filename: 'test.pdf',
        o_id: 3,
      },
      {
        data: IO.binread('test/fixtures/test1.pdf'),
        filename: 'test-again.pdf',
        o_id: 4,
      },
    ]

    files.each { |file|
      sha = Digest::SHA256.hexdigest( file[:data] )

      # add attachments
      store = Store.add(
        object: 'Test',
        o_id: file[:o_id],
        data: file[:data],
        filename: file[:filename],
        preferences: {},
        created_by_id: 1,
      )
      assert store

      # get list of attachments
      attachments = Store.list(
        object: 'Test',
        o_id: file[:o_id],
      )
      assert attachments

      # sha check
      sha_new = Digest::SHA256.hexdigest( attachments[0].content )
      assert_equal( sha, sha_new,  "check file #{file[:filename]}")

      # filename check
      assert_equal( file[:filename], attachments[0].filename )

      # provider check
      assert_equal( 'DB', attachments[0].provider )
    }

    success = Store::File.verify
    assert success, 'verify ok'

    Store::File.move( 'DB', 'File' )

    files.each { |file|
      sha = Digest::SHA256.hexdigest( file[:data] )

      # get list of attachments
      attachments = Store.list(
        object: 'Test',
        o_id: file[:o_id],
      )
      assert attachments

      # sha check
      sha_new = Digest::SHA256.hexdigest( attachments[0].content )
      assert_equal( sha, sha_new,  "check file #{file[:filename]}")

      # filename check
      assert_equal( file[:filename], attachments[0].filename )

      # provider check
      assert_equal( 'File', attachments[0].provider )
    }

    success = Store::File.verify
    assert success, 'verify ok'

    Store::File.move( 'File', 'DB' )

    files.each { |file|
      sha = Digest::SHA256.hexdigest( file[:data] )

      # get list of attachments
      attachments = Store.list(
        object: 'Test',
        o_id: file[:o_id],
      )
      assert attachments

      # sha check
      sha_new = Digest::SHA256.hexdigest( attachments[0].content )
      assert_equal( sha, sha_new,  "check file #{file[:filename]}")

      # filename check
      assert_equal( file[:filename], attachments[0].filename )

      # provider check
      assert_equal( 'DB', attachments[0].provider )

      # delete attachments
      success = Store.remove(
        object: 'Test',
        o_id: file[:o_id],
      )
      assert success

      # check attachments again
      attachments = Store.list(
        object: 'Test',
        o_id: file[:o_id],
      )
      assert !attachments[0]
    }
  end
end
