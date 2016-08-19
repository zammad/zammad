module Cti
  class Log < ApplicationModel
    self.table_name = 'cti_logs'

    store :preferences

    after_create :push_event, :push_caller_list
    after_update :push_event, :push_caller_list
    after_destroy :push_event, :push_caller_list

=begin

  Cti::Log.create(
    direction: 'in',
    from: '007',
    from_comment: 'AAA',
    to: '008',
    to_comment: 'BBB',
    call_id: '1',
    comment: '',
    state: 'newCall',
  )

  Cti::Log.create(
    direction: 'in',
    from: '007',
    from_comment: '',
    to: '008',
    to_comment: '',
    call_id: '2',
    comment: '',
    state: 'answer',
  )

  Cti::Log.create(
    direction: 'in',
    from: '009',
    from_comment: '',
    to: '010',
    to_comment: '',
    call_id: '3',
    comment: '',
    state: 'hangup',
  )

example data, can be used for demo

  Cti::Log.create(
    direction: 'in',
    from: '4930609854180',
    from_comment: 'Franz Bauer',
    to: '4930609811111',
    to_comment: 'Bob Smith',
    call_id: '00001',
    comment: '',
    state: 'newCall',
    done: false,
    preferences: {
      from: [
        {
          caller_id: '4930726128135',
          comment: nil,
          level: 'known',
          object: 'User',
          o_id: 2,
          user_id: 2,
        }
      ]
    }
  )

  Cti::Log.create(
    direction: 'out',
    from: '4930609854180',
    from_comment: 'Franz Bauer',
    to: '4930609811111',
    to_comment: 'Bob Smith',
    call_id: '00002',
    comment: '',
    state: 'newCall',
    preferences: {
      to: [
        {
          caller_id: '4930726128135',
          comment: nil,
          level: 'known',
          object: 'User',
          o_id: 2,
          user_id: 2,
        }
      ]
    }
  )

  Cti::Log.create(
    direction: 'in',
    from: '4930609854180',
    from_comment: 'Franz Bauer',
    to: '4930609811111',
    to_comment: 'Bob Smith',
    call_id: '00003',
    comment: '',
    state: 'answer',
    preferences: {
      from: [
        {
          caller_id: '4930726128135',
          comment: nil,
          level: 'known',
          object: 'User',
          o_id: 2,
          user_id: 2,
        }
      ]
    }
  )

  Cti::Log.create(
    direction: 'in',
    from: '4930609854180',
    from_comment: 'Franz Bauer',
    to: '4930609811111',
    to_comment: 'Bob Smith',
    call_id: '00004',
    comment: '',
    state: 'hangup',
    comment: 'normalClearing',
    done: false,
    preferences: {
      from: [
        {
          caller_id: '4930726128135',
          comment: nil,
          level: 'known',
          object: 'User',
          o_id: 2,
          user_id: 2,
        }
      ]
    }
  )

  Cti::Log.create(
    direction: 'in',
    from: '4930609854180',
    from_comment: 'Franz Bauer',
    to: '4930609811111',
    to_comment: 'Bob Smith',
    call_id: '00005',
    comment: '',
    state: 'hangup',
    start: Time.zone.now - 15.seconds,
    'end': Time.zone.now,
    preferences: {
      from: [
        {
          caller_id: '4930726128135',
          comment: nil,
          level: 'known',
          object: 'User',
          o_id: 2,
          user_id: 2,
        }
      ]
    }
  )

  Cti::Log.create(
    direction: 'in',
    from: '4930609854180',
    from_comment: 'Franz Bauer',
    to: '4930609811111',
    to_comment: '',
    call_id: '00006',
    comment: '',
    state: 'hangup',
    start: Time.zone.now - 15.seconds,
    'end': Time.zone.now,
    preferences: {
      from: [
        {
          caller_id: '4930726128135',
          comment: nil,
          level: 'known',
          object: 'User',
          o_id: 2,
          user_id: 2,
        }
      ]
    }
  )

  Cti::Log.create(
    direction: 'in',
    from: '4930609854180',
    from_comment: 'Franz Bauer',
    to: '4930609811111',
    to_comment: 'Bob Smith',
    call_id: '00007',
    comment: '',
    state: 'hangup',
    start: Time.zone.now - 15.seconds,
    'end': Time.zone.now,
    preferences: {
      from: [
        {
          caller_id: '4930726128135',
          comment: nil,
          level: 'maybe',
          object: 'User',
          o_id: 2,
          user_id: 2,
        }
      ]
    }
  )

=end

=begin

  Cti::Log.log

returns

  {
    list: [...]
    assets: {...}
  }

=end

    def self.log
      list = Cti::Log.order('created_at DESC, id DESC').limit(60)

      # add assets
      assets = {}
      list.each { |item|
        next if !item.preferences
        %w(from to).each { |direction|
          next if !item.preferences[direction]
          item.preferences[direction].each { |caller_id|
            next if !caller_id['user_id']
            user = User.lookup(id: caller_id['user_id'])
            next if !user
            assets = user.assets(assets)
          }
        }
      }

      {
        list: list,
        assets: assets,
      }
    end

    def push_event
      users = User.with_permissions('cti.agent')
      users.each { |user|

        # send notify about event
        Sessions.send_to(
          user.id,
          {
            event: 'cti_event',
            data: self,
          },
        )
      }
    end

    def push_caller_list
      list = Cti::Log.log

      users = User.with_permissions('cti.agent')
      users.each { |user|

        # send notify on create/update/delete
        Sessions.send_to(
          user.id,
          {
            event: 'cti_list_push',
            data: list,
          },
        )
      }
    end
  end
end
