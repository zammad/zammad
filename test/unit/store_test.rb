# encoding: utf-8
require 'test_helper'

class StoreTest < ActiveSupport::TestCase
  test 'store fs - get_location' do
    sha = 'ed7002b439e9ac845f22357d822bac1444730fbdb6016d3ec9432297b9ec9f73'
    location = Store::Provider::File.get_location(sha)
    assert_equal("#{Rails.root}/storage/fs/ed70/02b4/39e9a/c845f/22357d8/22bac14/44730fbdb6016d3ec9432297b9ec9f73", location)
  end

  test 'store fs - empty dir remove' do
    sha = 'ed7002b439e9ac845f22357d822bac1444730fbdb6016d3ec9432297b9ec9f73'
    content = 'content'
    location = Store::Provider::File.get_location(sha)
    result = Store::Provider::File.add(content, sha)
    assert(result)
    exists = File.exist?(location)
    assert(exists)
    result = Store::Provider::File.delete(sha)
    exists = File.exist?(location)
    assert(!exists)
    exists = File.exist?("#{Rails.root}/storage/fs/ed70/02b4")
    assert(!exists)
    exists = File.exist?("#{Rails.root}/storage/fs/ed70/")
    assert(!exists)
    exists = File.exist?("#{Rails.root}/storage/fs/")
    assert(exists)
    exists = File.exist?("#{Rails.root}/storage/")
    assert(exists)
  end

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
