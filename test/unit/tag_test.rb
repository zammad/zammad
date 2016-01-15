# encoding: utf-8
require 'test_helper'

class TagTest < ActiveSupport::TestCase
  test 'tags' do
    tests = [

      # test 1
      {
        tag_add: {
          item: 'tag1',
          object: 'Object1',
          o_id: 123,
          created_by_id: 1
        },
        verify: {
          object: 'Object1',
          items: {
            'tag1' => true,
            'tag2' => false,
          },
        },
      },

      # test 2
      {
        tag_add: {
          item: 'tag2',
          object: 'Object1',
          o_id: 123,
          created_by_id: 1
        },
        verify: {
          object: 'Object1',
          items: {
            'tag1' => true,
            'tag2' => true,
          },
        },
      },

      # test 2
      {
        tag_add: {
          item: 'tagöäüß1',
          object: 'Object2',
          o_id: 123,
          created_by_id: 1
        },
        verify: {
          object: 'Object2',
          items: {
            'tagöäüß1' => true,
            'tag2'     => false,
          },
        },
      },

      # test 4
      {
        tag_add: {
          item: 'Tagöäüß2',
          object: 'Object2',
          o_id: 123,
          created_by_id: 1
        },
        verify: {
          object: 'Object2',
          items: {
            'tagöäüß1' => true,
            'tagöäüß2' => true,
            'tagöäüß3' => false,
          },
        },
      },

      # test 5
      {
        tag_remove: {
          item: 'tag1',
          object: 'Object1',
          o_id: 123,
          created_by_id: 1
        },
        verify: {
          object: 'Object1',
          items: {
            'tag1' => false,
            'tag2' => true,
          },
        },
      },

    ]
    tests.each { |test|
      tags = nil
      if test[:tag_add]
        tags    = test[:tag_add]
        success = Tag.tag_add( tags )
        assert( success, 'Tag.tag_add successful')
      else
        tags    = test[:tag_remove]
        success = Tag.tag_remove( tags )
        assert( success, 'Tag.tag_remove successful')
      end
      list = Tag.tag_list( tags )
      test[:verify][:items].each {|key, value|
        if value == true
          assert( list.include?( key ), "Tag verify - should exists but exists #{key}")
        else
          assert( !list.include?( key ), "Tag verify - exists but should not #{key}")
        end
      }
    }

    # delete tags
    tests.each { |test|
      tags = nil
      tags = if test[:tag_add]
               test[:tag_add]
             else
               test[:tag_remove]
             end
      success = Tag.tag_remove( tags )
      assert( success, 'Tag.tag_remove successful')
      list = Tag.tag_list( tags )
      assert( !list.include?( tags[:item] ), 'Tag entry destroyed')
    }
  end
end
