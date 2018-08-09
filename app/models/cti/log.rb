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
    start_at: Time.zone.now - 15.seconds,
    end_at: Time.zone.now,
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
    start_at: Time.zone.now - 15.seconds,
    end_at: Time.zone.now,
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
    start_at: Time.zone.now - 15.seconds,
    end_at: Time.zone.now,
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

  Cti::Log.create(
    direction: 'in',
    from: '4930609854180',
    to: '4930609811112',
    call_id: '00008',
    comment: '',
    state: 'hangup',
    start_at: Time.zone.now - 20.seconds,
    end_at: Time.zone.now,
    preferences: {}
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
      assets = list.map(&:preferences)
                   .map { |p| p.slice(:from, :to) }
                   .map(&:values).flatten
                   .map { |caller_id| caller_id[:user_id] }.compact
                   .map { |user_id| User.lookup(id: user_id) }.compact
                   .each.with_object({}) { |user, a| user.assets(a) }

      {
        list: list,
        assets: assets,
      }
    end

=begin

processes a incoming event

Cti::Log.process(
  'cause' => '',
  'event' => 'newCall',
  'user' => 'user 1',
  'from' => '4912347114711',
  'to' => '4930600000000',
  'callId' => '4991155921769858278-1', # or call_id
  'direction' => 'in',
)

=end

    def self.process(params)
      comment = params['cause']
      event   = params['event']
      user    = params['user']
      call_id = params['callId'] || params['call_id']
      if user.class == Array
        user = user.join(', ')
      end

      from_comment = nil
      to_comment = nil
      preferences = nil
      if params['direction'] == 'in'
        to_comment = user
        from_comment, preferences = CallerId.get_comment_preferences(params['from'], 'from')
      else
        from_comment = user
        to_comment, preferences = CallerId.get_comment_preferences(params['to'], 'to')
      end

      case event
      when 'newCall'
        create(
          direction: params['direction'],
          from: params['from'],
          from_comment: from_comment,
          to: params['to'],
          to_comment: to_comment,
          call_id: call_id,
          comment: comment,
          state: event,
          initialized_at: Time.zone.now,
          preferences: preferences,
        )
      when 'answer'
        log = find_by(call_id: call_id)
        raise "No such call_id #{call_id}" if !log
        log.state = 'answer'
        log.start_at = Time.zone.now
        log.duration_waiting_time = log.start_at.to_i - log.initialized_at.to_i
        if user
          log.to_comment = user
        end
        log.comment = comment
        log.save
      when 'hangup'
        log = find_by(call_id: call_id)
        raise "No such call_id #{call_id}" if !log
        if params['direction'] == 'in' && log.state == 'newCall'
          log.done = false
        end
        if params['direction'] == 'in' && log.to_comment == 'voicemail'
          log.done = false
        end
        log.state = 'hangup'
        log.end_at = Time.zone.now
        if log.start_at
          log.duration_talking_time = log.start_at.to_i - log.end_at.to_i
        elsif !log.duration_waiting_time && log.initialized_at
          log.duration_waiting_time = log.end_at.to_i - log.initialized_at.to_i
        end
        log.comment = comment
        log.save
      else
        raise ArgumentError, "Unknown event #{event.inspect}"
      end
    end

    def push_event
      users = User.with_permissions('cti.agent')
      users.each do |user|

        # send notify about event
        Sessions.send_to(
          user.id,
          {
            event: 'cti_event',
            data: self,
          },
        )
      end
    end

    def push_caller_list
      list = Cti::Log.log

      users = User.with_permissions('cti.agent')
      users.each do |user|

        # send notify on create/update/delete
        Sessions.send_to(
          user.id,
          {
            event: 'cti_list_push',
            data: list,
          },
        )
      end
    end

=begin

cleanup caller logs

  Cti::Log.cleanup

optional you can put the max oldest chat entries as argument

  Cti::Log.cleanup(12.months)

=end

    def self.cleanup(diff = 12.months)
      Cti::Log.where('created_at < ?', Time.zone.now - diff).delete_all
      true
    end

    # adds virtual attributes when rendering #to_json
    # see http://api.rubyonrails.org/classes/ActiveModel/Serialization.html
    def attributes
      virtual_attributes = {
        'from_pretty' => from_pretty,
        'to_pretty' => to_pretty,
      }

      super.merge(virtual_attributes)
    end

    def from_pretty
      parsed = TelephoneNumber.parse(from&.sub(/^\+?/, '+'))
      parsed.send(parsed.valid? ? :international_number : :original_number)
    end

    def to_pretty
      parsed = TelephoneNumber.parse(to&.sub(/^\+?/, '+'))
      parsed.send(parsed.valid? ? :international_number : :original_number)
    end
  end
end
