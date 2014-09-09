# encoding: utf-8
require 'test_helper'

class TagTest < ActiveSupport::TestCase
  test 'tags' do
    tests = [

      # test 1
      {
        :tag_add => {
          :item          => 'tag1',
          :object        => 'Object1',
          :o_id          => 123,
          :created_by_id => 1
        },
        :verify => {
          :object => 'Object1',
          :items => {
            'tag1' => true,
            'tag2' => false,
          },
        },
      },

      # test 2
      {
        :tag_add => {
          :item          => 'tag2',
          :object        => 'Object1',
          :o_id          => 123,
          :created_by_id => 1
        },
        :verify => {
          :object => 'Object1',
          :items => {
            'tag1' => true,
            'tag2' => true,
          },
        },
      },

      # test 2
      {
        :tag_add => {
          :item          => 'tagöäüß1',
          :object        => 'Object2',
          :o_id          => 123,
          :created_by_id => 1
        },
        :verify => {
          :object => 'Object2',
          :items => {
            'tagöäüß1' => true,
            'tag2'     => false,
          },
        },
      },

      # test 4
      {
        :tag_add => {
          :item          => 'Tagöäüß2',
          :object        => 'Object2',
          :o_id          => 123,
          :created_by_id => 1
        },
        :verify => {
          :object => 'Object2',
          :items => {
            'tagöäüß1' => true,
            'tagöäüß2' => true,
            'tagöäüß3' => false,
          },
        },
      },

      # test 5
      {
        :tag_remove => {
          :item          => 'tag1',
          :object        => 'Object1',
          :o_id          => 123,
          :created_by_id => 1
        },
        :verify => {
          :object => 'Object1',
          :items => {
            'tag1' => false,
            'tag2' => true,
          },
        },
      },

    ]
    tests.each { |test|
      success = Tag.tag_add( test[:tag_add] )
      assert( success, "Tag.tag_add successful")
      list = Tag.tag_list( test[:tag_add] )
      test[:verify][:items].each {|key, value|
        if value == true
          assert( list.include?( key ), "Tag verify #{ test[:tag_add][:item] }")
        else
          assert( !list.include?( key ), "Tag verify #{ test[:tag_add][:item] }")
        end
      }
    }

    # delete tags
    tests.each { |test|
      success = Tag.tag_remove( test[:tag_add] )
      assert( success, "Tag.tag_remove successful")
      list = Tag.tag_list( test[:tag_add] )
      assert( !list.include?( test[:tag_add][:item] ), "Tag entry destroyed")
    }
  end
end
