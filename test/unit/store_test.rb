# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class StoreTest < ActiveSupport::TestCase
  test 'store fs - get_location' do
    sha = 'ed7002b439e9ac845f22357d822bac1444730fbdb6016d3ec9432297b9ec9f73'
    location = Store::Provider::File.get_location(sha)
    assert_equal(Rails.root.join('storage/fs/ed70/02b4/39e9a/c845f/22357d8/22bac14/44730fbdb6016d3ec9432297b9ec9f73').to_s, location)
  end

  test 'store fs - empty dir remove' do
    sha = 'ed7002b439e9ac845f22357d822bac1444730fbdb6016d3ec9432297b9ec9f73'
    content = 'content'
    location = Store::Provider::File.get_location(sha)
    result = Store::Provider::File.add(content, sha)
    assert(result)
    exists = File.exist?(location)
    assert(exists)
    Store::Provider::File.delete(sha)
    exists = File.exist?(location)
    assert_not(exists)
    exists = File.exist?(Rails.root.join('storage/fs/ed70/02b4'))
    assert_not(exists)
    exists = File.exist?(Rails.root.join('storage/fs/ed70'))
    assert_not(exists)
    exists = File.exist?(Rails.root.join('storage/fs'))
    assert(exists)
    exists = File.exist?(Rails.root.join('storage'))
    assert(exists)
  end

  test 'store attachment and move it between backends' do
    files = [
      {
        data:     'hello world',
        filename: 'test.txt',
        o_id:     1,
      },
      {
        data:     'hello world äöüß',
        filename: 'testäöüß.txt',
        o_id:     2,
      },
      {
        data:     File.binread(Rails.root.join('test/data/pdf/test1.pdf')),
        filename: 'test.pdf',
        o_id:     3,
      },
      {
        data:     File.binread(Rails.root.join('test/data/pdf/test1.pdf')),
        filename: 'test-again.pdf',
        o_id:     4,
      },
    ]

    files.each do |file|
      sha = Digest::SHA256.hexdigest(file[:data])

      # add attachments
      store = Store.add(
        object:        'Test',
        o_id:          file[:o_id],
        data:          file[:data],
        filename:      file[:filename],
        preferences:   {},
        created_by_id: 1,
      )
      assert store

      # get list of attachments
      attachments = Store.list(
        object: 'Test',
        o_id:   file[:o_id],
      )
      assert attachments

      # sha check
      sha_new = Digest::SHA256.hexdigest(attachments[0].content)
      assert_equal(sha, sha_new, "check file #{file[:filename]}")

      # filename check
      assert_equal(file[:filename], attachments[0].filename)

      # provider check
      assert_equal('DB', attachments[0].provider)
    end

    success = Store::File.verify
    assert success, 'verify ok'

    Store::File.move('DB', 'File')

    files.each do |file|
      sha = Digest::SHA256.hexdigest(file[:data])

      # get list of attachments
      attachments = Store.list(
        object: 'Test',
        o_id:   file[:o_id],
      )
      assert attachments

      # sha check
      sha_new = Digest::SHA256.hexdigest(attachments[0].content)
      assert_equal(sha, sha_new, "check file #{file[:filename]}")

      # filename check
      assert_equal(file[:filename], attachments[0].filename)

      # provider check
      assert_equal('File', attachments[0].provider)
    end

    success = Store::File.verify
    assert success, 'verify ok'

    Store::File.move('File', 'DB')

    files.each do |file|
      sha = Digest::SHA256.hexdigest(file[:data])

      # get list of attachments
      attachments = Store.list(
        object: 'Test',
        o_id:   file[:o_id],
      )
      assert(attachments)
      assert_equal(attachments.count, 1)

      # sha check
      sha_new = Digest::SHA256.hexdigest(attachments[0].content)
      assert_equal(sha, sha_new, "check file #{file[:filename]}")

      # filename check
      assert_equal(file[:filename], attachments[0].filename)

      # provider check
      assert_equal('DB', attachments[0].provider)

      # delete attachments
      success = Store.remove(
        object: 'Test',
        o_id:   file[:o_id],
      )
      assert(success)

      # check attachments again
      attachments = Store.list(
        object: 'Test',
        o_id:   file[:o_id],
      )
      assert_not(attachments[0])
    end
  end

  test 'test resizable' do

    # not possible
    store = Store.add(
      object:        'SomeObject1',
      o_id:          rand(1_234_567_890),
      data:          File.binread(Rails.root.join('test/data/upload/upload1.txt')),
      filename:      'test1.pdf',
      preferences:   {
        content_type: 'text/plain',
        content_id:   234,
      },
      created_by_id: 1,
    )
    assert_not(store.preferences.key?(:resizable))
    assert_not(store.preferences.key?(:content_inline))
    assert_not(store.preferences.key?(:content_preview))
    assert_raises(RuntimeError) do
      store.content_inline
    end
    assert_raises(RuntimeError) do
      store.content_preview
    end

    # not possible
    store = Store.add(
      object:        'SomeObject2',
      o_id:          rand(1_234_567_890),
      data:          File.binread(Rails.root.join('test/data/upload/upload1.txt')),
      filename:      'test1.pdf',
      preferences:   {
        content_type: 'image/jpg',
        content_id:   234,
      },
      created_by_id: 1,
    )
    assert_equal(store.preferences[:resizable], false)
    assert_not(store.preferences.key?(:content_inline))
    assert_not(store.preferences.key?(:content_preview))
    assert_raises(RuntimeError) do
      store.content_inline
    end
    assert_raises(RuntimeError) do
      store.content_preview
    end

    # possible (preview and inline)
    store = Store.add(
      object:        'SomeObject3',
      o_id:          rand(1_234_567_890),
      data:          File.binread(Rails.root.join('test/data/upload/upload2.jpg')),
      filename:      'test1.pdf',
      preferences:   {
        content_type: 'image/jpg',
        content_id:   234,
      },
      created_by_id: 1,
    )
    assert_equal(store.preferences[:resizable], true)
    assert_equal(store.preferences[:content_inline], true)
    assert_equal(store.preferences[:content_preview], true)

    temp_file = ::Tempfile.new.path
    File.binwrite(temp_file, store.content_inline)
    image = Rszr::Image.load(temp_file)
    assert_equal(image.width, 1800)

    temp_file = ::Tempfile.new.path
    File.binwrite(temp_file, store.content_preview)
    image = Rszr::Image.load(temp_file)
    assert_equal(image.width, 200)

    # possible (preview only)
    store = Store.add(
      object:        'SomeObject4',
      o_id:          rand(1_234_567_890),
      data:          File.binread(Rails.root.join('test/data/image/1000x1000.png')),
      filename:      'test1.png',
      preferences:   {
        content_type: 'image/png',
        content_id:   234,
      },
      created_by_id: 1,
    )
    assert_equal(store.preferences[:resizable], true)
    assert_nil(store.preferences[:content_inline])
    assert_equal(store.preferences[:content_preview], true)
    assert_raises(RuntimeError) do
      store.content_inline
    end

    temp_file = ::Tempfile.new.path
    File.binwrite(temp_file, store.content_preview)
    image = Rszr::Image.load(temp_file)
    assert_equal(image.width, 200)

    # no preview or inline needed
    store = Store.add(
      object:        'SomeObject5',
      o_id:          rand(1_234_567_890),
      data:          File.binread(Rails.root.join('test/data/image/1x1.png')),
      filename:      'test1.png',
      preferences:   {
        content_type: 'image/png',
        content_id:   234,
      },
      created_by_id: 1,
    )
    assert_nil(store.preferences[:resizable])
    assert_nil(store.preferences[:content_inline])
    assert_nil(store.preferences[:content_preview])
    assert_raises(RuntimeError) do
      store.content_inline
    end
    assert_raises(RuntimeError) do
      store.content_preview
    end

    # no preview or inline needed
    store = Store.add(
      object:        'SomeObject6',
      o_id:          rand(1_234_567_890),
      data:          File.binread(Rails.root.join('test/data/image/4000x1.jpg')),
      filename:      'test1.jpg',
      preferences:   {
        content_type: 'image/jpg',
        content_id:   234,
      },
      created_by_id: 1,
    )
    assert_nil(store.preferences[:resizable])
    assert_nil(store.preferences[:content_inline])
    assert_nil(store.preferences[:content_preview])

    # possible (no preview or inline needed)
    store = Store.add(
      object:        'SomeObject7',
      o_id:          rand(1_234_567_890),
      data:          File.binread(Rails.root.join('test/data/image/8000x25.jpg')),
      filename:      'test1.jpg',
      preferences:   {
        content_type: 'image/jpg',
        content_id:   234,
      },
      created_by_id: 1,
    )
    assert_nil(store.preferences[:resizable])
    assert_nil(store.preferences[:content_inline])
    assert_nil(store.preferences[:content_preview])

    # possible (preview and inline)
    store = Store.add(
      object:        'SomeObject8',
      o_id:          rand(1_234_567_890),
      data:          File.binread(Rails.root.join('test/data/image/8000x300.jpg')),
      filename:      'test1.jpg',
      preferences:   {
        content_type: 'image/jpg',
        content_id:   234,
      },
      created_by_id: 1,
    )
    assert_equal(store.preferences[:resizable], true)
    assert_equal(store.preferences[:content_inline], true)
    assert_equal(store.preferences[:content_preview], true)

    # possible, but skipped (preview and inline)
    Setting.set('import_mode', true)
    store = Store.add(
      object:        'SomeObject3',
      o_id:          rand(1_234_567_890),
      data:          File.binread(Rails.root.join('test/data/upload/upload2.jpg')),
      filename:      'test1.pdf',
      preferences:   {
        content_type: 'image/jpg',
        content_id:   234,
      },
      created_by_id: 1,
    )
    assert_nil(store.preferences[:resizable])
    assert_nil(store.preferences[:content_inline])
    assert_nil(store.preferences[:content_preview])
  end

  test 'test maximal preferences size check with one oversized content' do
    store = Store.add(
      object:        'SomeObject1',
      o_id:          rand(1_234_567_890),
      data:          File.binread(Rails.root.join('test/data/upload/upload1.txt')),
      filename:      'test1.pdf',
      preferences:   {
        content_type: 'text/plain',
        content_id:   234,
        some_key:     '0' * 2500,
      },
      created_by_id: 1,
    )
    assert_not(store.preferences.key?(:some_key))
    assert(store.preferences.key?(:content_id))
    assert(store.preferences.key?(:content_type))
  end

  test 'test maximal preferences size check with two oversized content' do
    store = Store.add(
      object:        'SomeObject1',
      o_id:          rand(1_234_567_890),
      data:          File.binread(Rails.root.join('test/data/upload/upload1.txt')),
      filename:      'test1.pdf',
      preferences:   {
        content_type: 'text/plain',
        content_id:   234,
        some_key1:    '0' * 2000,
        some_key2:    '0' * 2000,
      },
      created_by_id: 1,
    )
    assert_not(store.preferences.key?(:some_key1))
    assert(store.preferences.key?(:some_key2))
    assert(store.preferences.key?(:content_id))
    assert(store.preferences.key?(:content_type))
  end

  test 'test maximal preferences size check with one oversized key' do
    preferences = {
      content_type: 'text/plain',
      content_id:   234,
    }
    some_key1 = '0' * 2500
    preferences[some_key1] = 'some content'

    store = Store.add(
      object:        'SomeObject1',
      o_id:          rand(1_234_567_890),
      data:          File.binread(Rails.root.join('test/data/upload/upload1.txt')),
      filename:      'test1.pdf',
      preferences:   preferences,
      created_by_id: 1,
    )
    assert_not(store.preferences.key?(some_key1))
    assert(store.preferences.key?(:content_id))
    assert(store.preferences.key?(:content_type))
  end

  test 'test maximal preferences size check with two oversized key' do
    preferences = {
      content_type: 'text/plain',
      content_id:   234,
    }
    some_key1 = '0' * 1500
    preferences[some_key1] = 'some content'
    some_key2 = '1' * 1500
    preferences[some_key2] = 'some content'

    store = Store.add(
      object:        'SomeObject1',
      o_id:          rand(1_234_567_890),
      data:          File.binread(Rails.root.join('test/data/upload/upload1.txt')),
      filename:      'test1.pdf',
      preferences:   preferences,
      created_by_id: 1,
    )
    assert_not(store.preferences.key?(some_key1))
    assert(store.preferences.key?(some_key2))
    assert(store.preferences.key?(:content_id))
    assert(store.preferences.key?(:content_type))
  end

end
