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

      {
        tag_add: {
          item: 'TAG2',
          object: 'Object1',
          o_id: 123,
          created_by_id: 1
        },
        verify: {
          object: 'Object1',
          items: {
            'tag1' => true,
            'tag2' => true,
            'TAG2' => true,
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
            'Tagöäüß2' => true,
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
            'TAG2' => true,
          },
        },
      },

      # test 5
      {
        tag_remove: {
          item: 'TAG2',
          object: 'Object1',
          o_id: 123,
          created_by_id: 1
        },
        verify: {
          object: 'Object1',
          items: {
            'tag1' => false,
            'tag2' => true,
            'TAG2' => false,
          },
        },
      },

    ]
    tests.each { |test|
      tags = nil
      if test[:tag_add]
        tags    = test[:tag_add]
        success = Tag.tag_add(tags)
        assert(success, 'Tag.tag_add successful')
      else
        tags    = test[:tag_remove]
        success = Tag.tag_remove(tags)
        assert(success, 'Tag.tag_remove successful')
      end
      list = Tag.tag_list(tags)
      test[:verify][:items].each { |key, value|
        if value == true
          assert(list.include?(key), "Tag verify - should exists but exists #{key}")
        else
          assert(!list.include?(key), "Tag verify - exists but should not #{key}")
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
      success = Tag.tag_remove(tags)
      assert(success, 'Tag.tag_remove successful')
      list = Tag.tag_list(tags)
      assert(!list.include?(tags[:item]), 'Tag entry destroyed')
    }
  end

  test 'tags - real live' do

    ticket1 = Ticket.create(
      title: 'some title tag1',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket2 = Ticket.create(
      title: 'some title tag2',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    travel 2.seconds

    ticket1.tag_add('some tag1', 1)
    ticket1.tag_add('some tag2 ', 1)
    ticket1.tag_add(' some tag3', 1)
    ticket1.tag_add('some TAG4', 1)
    ticket1.tag_add(' some tag4', 1)

    ticket2.tag_add('some tag3', 1)
    ticket2.tag_add('some TAG4', 1)
    ticket2.tag_add('some tag4 ', 1)

    ticket1.tag_remove('some tag1', 1)

    ticket1_lookup1 = Ticket.lookup(id: ticket1.id)
    assert_not_equal(ticket1.updated_at.to_s, ticket1_lookup1.updated_at.to_s)
    ticket2_lookup1 = Ticket.lookup(id: ticket2.id)
    assert_not_equal(ticket2.updated_at.to_s, ticket2_lookup1.updated_at.to_s)

    tags_ticket1 = ticket1.tag_list
    assert_equal(4, tags_ticket1.count)
    assert(tags_ticket1.include?('some tag2'))
    assert(tags_ticket1.include?('some tag3'))
    assert(tags_ticket1.include?('some TAG4'))
    assert(tags_ticket1.include?('some tag4'))

    tags_ticket2 = ticket2.tag_list
    assert_equal(3, tags_ticket2.count)
    assert(tags_ticket2.include?('some tag3'))
    assert(tags_ticket2.include?('some TAG4'))
    assert(tags_ticket2.include?('some tag4'))

    # rename tag
    travel 2.seconds
    tag_item3 = Tag::Item.find_by(name: 'some tag3')
    Tag::Item.rename(
      id: tag_item3.id,
      name: ' some tag33',
      created_by_id: 1,
    )

    ticket1_lookup2 = Ticket.lookup(id: ticket1.id)
    assert_not_equal(ticket1_lookup2.updated_at.to_s, ticket1_lookup1.updated_at.to_s)
    ticket2_lookup2 = Ticket.lookup(id: ticket2.id)
    assert_not_equal(ticket2_lookup2.updated_at.to_s, ticket2_lookup1.updated_at.to_s)

    tags_ticket1 = ticket1.tag_list
    assert_equal(4, tags_ticket1.count)
    assert(tags_ticket1.include?('some tag2'))
    assert(tags_ticket1.include?('some tag33'))
    assert(tags_ticket1.include?('some TAG4'))
    assert(tags_ticket1.include?('some tag4'))

    tags_ticket2 = ticket2.tag_list
    assert_equal(3, tags_ticket2.count)
    assert(tags_ticket2.include?('some tag33'))
    assert(tags_ticket2.include?('some TAG4'))
    assert(tags_ticket2.include?('some tag4'))

    # merge tags
    travel 2.seconds
    Tag::Item.rename(
      id: tag_item3.id,
      name: 'some tag2',
      created_by_id: 1,
    )

    ticket1_lookup3 = Ticket.lookup(id: ticket1.id)
    assert_not_equal(ticket1_lookup3.updated_at.to_s, ticket1_lookup2.updated_at.to_s)
    ticket2_lookup3 = Ticket.lookup(id: ticket2.id)
    assert_not_equal(ticket2_lookup3.updated_at.to_s, ticket2_lookup2.updated_at.to_s)

    tags_ticket1 = ticket1.tag_list
    assert_equal(3, tags_ticket1.count)
    assert(tags_ticket1.include?('some tag2'))
    assert(tags_ticket1.include?('some TAG4'))
    assert(tags_ticket1.include?('some tag4'))

    tags_ticket2 = ticket2.tag_list
    assert_equal(3, tags_ticket2.count)
    assert(tags_ticket2.include?('some tag2'))
    assert(tags_ticket2.include?('some TAG4'))
    assert(tags_ticket2.include?('some tag4'))

    assert_not(Tag::Item.find_by(id: tag_item3.id))

    # remove tag item
    travel 2.seconds
    tag_item4 = Tag::Item.find_by(name: 'some TAG4')
    Tag::Item.remove(tag_item4.id)

    tags_ticket1 = ticket1.tag_list
    assert_equal(2, tags_ticket1.count)
    assert(tags_ticket1.include?('some tag2'))
    assert(tags_ticket1.include?('some tag4'))

    tags_ticket2 = ticket2.tag_list
    assert_equal(2, tags_ticket2.count)
    assert(tags_ticket2.include?('some tag2'))
    assert(tags_ticket2.include?('some tag4'))

    assert_not(Tag::Item.find_by(id: tag_item4.id))

    ticket1_lookup4 = Ticket.lookup(id: ticket1.id)
    assert_not_equal(ticket1_lookup4.updated_at.to_s, ticket1_lookup3.updated_at.to_s)
    ticket2_lookup4 = Ticket.lookup(id: ticket2.id)
    assert_not_equal(ticket2_lookup4.updated_at.to_s, ticket2_lookup3.updated_at.to_s)
    travel_back
  end

  test 'tags - rename tag with same name' do

    ticket1 = Ticket.create(
      title: 'rename tag1',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket2 = Ticket.create(
      title: 'rename tag2',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket1.tag_add('some rename tag1', 1)
    ticket1.tag_add('some rename tag2 ', 1)

    ticket2.tag_add('some rename tag2', 1)

    tags_ticket1 = ticket1.tag_list
    assert_equal(2, tags_ticket1.count)
    assert(tags_ticket1.include?('some rename tag1'))
    assert(tags_ticket1.include?('some rename tag2'))

    tags_ticket2 = ticket2.tag_list
    assert_equal(1, tags_ticket2.count)
    assert(tags_ticket2.include?('some rename tag2'))

    tag_item1 = Tag::Item.find_by(name: 'some rename tag1')
    Tag::Item.rename(
      id: tag_item1.id,
      name: ' some rename tag1',
      created_by_id: 1,
    )

    tags_ticket1 = ticket1.tag_list
    assert_equal(2, tags_ticket1.count)
    assert(tags_ticket1.include?('some rename tag1'))
    assert(tags_ticket1.include?('some rename tag2'))

    tags_ticket2 = ticket2.tag_list
    assert_equal(1, tags_ticket2.count)
    assert(tags_ticket2.include?('some rename tag2'))

  end

  test 'tags - rename and merge tag with existing tag' do

    ticket1 = Ticket.create(
      title: 'rename tag1',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket2 = Ticket.create(
      title: 'rename tag2',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket1.tag_add('tagname1', 1)
    ticket1.tag_add('tagname2', 1)

    ticket2.tag_add('Tagname2', 1)

    tags_ticket1 = ticket1.tag_list
    assert_equal(2, tags_ticket1.count)
    assert(tags_ticket1.include?('tagname1'))
    assert(tags_ticket1.include?('tagname2'))

    tags_ticket2 = ticket2.tag_list
    assert_equal(1, tags_ticket2.count)
    assert(tags_ticket2.include?('Tagname2'))

    tag_item1 = Tag::Item.lookup(name: 'Tagname2')
    Tag::Item.rename(
      id:            tag_item1.id,
      name:          'tagname2',
      created_by_id: 1,
    )

    tags_ticket1 = ticket1.tag_list
    assert_equal(2, tags_ticket1.count)
    assert(tags_ticket1.include?('tagname1'))
    assert(tags_ticket1.include?('tagname2'))

    tags_ticket2 = ticket2.tag_list
    assert_equal(1, tags_ticket2.count)
    assert(tags_ticket2.include?('tagname2'))

  end
end
