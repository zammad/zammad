# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Cti
  class Log < ApplicationModel
    include HasSearchIndexBackend

    self.table_name = 'cti_logs'

    store :preferences, accessors: %i[from_pretty to_pretty]

    validates :state, format: { with: %r{\A(newCall|answer|hangup)\z},  message: 'newCall|answer|hangup is allowed' }

    before_create :set_pretty
    before_update :set_pretty
    after_commit :push_caller_list_update

=begin

  Cti::Log.create!(
    direction: 'in',
    from: '007',
    from_comment: '',
    to: '008',
    to_comment: 'BBB',
    call_id: '1',
    comment: '',
    state: 'newCall',
    done: true,
  )

  Cti::Log.create!(
    direction: 'in',
    from: '007',
    from_comment: '',
    to: '008',
    to_comment: '',
    call_id: '2',
    comment: '',
    state: 'answer',
    done: true,
  )

  Cti::Log.create!(
    direction: 'in',
    from: '009',
    from_comment: '',
    to: '010',
    to_comment: '',
    call_id: '3',
    comment: '',
    state: 'hangup',
    done: true,
  )

example data, can be used for demo

  Cti::Log.create!(
    direction: 'in',
    from: '4930609854180',
    from_comment: 'Franz Bauer',
    to: '4930609811111',
    to_comment: 'Bob Smith',
    call_id: '435452113',
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
        },
        {
          caller_id: '4930726128135',
          comment: nil,
          level: 'maybe',
          object: 'User',
          o_id: 2,
          user_id: 3,
        },
      ]
    },
    created_at: Time.zone.now,
  )

  Cti::Log.create!(
    direction: 'out',
    from: '4930609854180',
    from_comment: 'Franz Bauer',
    to: '4930609811111',
    to_comment: 'Bob Smith',
    call_id: rand(999_999_999),
    comment: '',
    state: 'newCall',
    done: true,
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
    },
    created_at: Time.zone.now - 20.seconds,
  )

  Cti::Log.create!(
    direction: 'in',
    from: '4930609854180',
    from_comment: 'Franz Bauer',
    to: '4930609811111',
    to_comment: 'Bob Smith',
    call_id: rand(999_999_999),
    comment: '',
    state: 'answer',
    done: true,
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
    },
    initialized_at: Time.zone.now - 20.seconds,
    start_at: Time.zone.now - 30.seconds,
    duration_waiting_time: 20,
    created_at: Time.zone.now - 20.seconds,
  )

  Cti::Log.create!(
    direction: 'in',
    from: '4930609854180',
    from_comment: 'Franz Bauer',
    to: '4930609811111',
    to_comment: 'Bob Smith',
    call_id: rand(999_999_999),
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
    },
    initialized_at: Time.zone.now - 80.seconds,
    start_at: Time.zone.now - 45.seconds,
    end_at: Time.zone.now,
    duration_waiting_time: 35,
    duration_talking_time: 45,
    created_at: Time.zone.now - 80.seconds,
  )

  Cti::Log.create!(
    direction: 'in',
    from: '4930609854180',
    from_comment: 'Franz Bauer',
    to: '4930609811111',
    to_comment: 'Bob Smith',
    call_id: rand(999_999_999),
    comment: '',
    state: 'hangup',
    done: true,
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
    },
    initialized_at: Time.zone.now - 5.minutes,
    start_at: Time.zone.now - 3.minutes,
    end_at: Time.zone.now - 20.seconds,
    duration_waiting_time: 120,
    duration_talking_time: 160,
    created_at: Time.zone.now - 5.minutes,
  )

  Cti::Log.create!(
    direction: 'in',
    from: '4930609854180',
    from_comment: 'Franz Bauer',
    to: '4930609811111',
    to_comment: '',
    call_id: rand(999_999_999),
    comment: '',
    state: 'hangup',
    done: true,
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
    },
    initialized_at: Time.zone.now - 60.minutes,
    start_at: Time.zone.now - 59.minutes,
    end_at: Time.zone.now - 2.minutes,
    duration_waiting_time: 60,
    duration_talking_time: 3420,
    created_at: Time.zone.now - 60.minutes,
  )

  Cti::Log.create!(
    direction: 'in',
    from: '4930609854180',
    from_comment: 'Franz Bauer',
    to: '4930609811111',
    to_comment: 'Bob Smith',
    call_id: rand(999_999_999),
    comment: '',
    state: 'hangup',
    done: true,
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
    },
    initialized_at: Time.zone.now - 240.minutes,
    start_at: Time.zone.now - 235.minutes,
    end_at: Time.zone.now - 222.minutes,
    duration_waiting_time: 300,
    duration_talking_time: 1080,
    created_at: Time.zone.now - 240.minutes,
  )

  Cti::Log.create!(
    direction: 'in',
    from: '4930609854180',
    to: '4930609811112',
    call_id: rand(999_999_999),
    comment: '',
    state: 'hangup',
    done: true,
    start_at: Time.zone.now - 20.seconds,
    end_at: Time.zone.now,
    preferences: {},
    initialized_at: Time.zone.now - 1440.minutes,
    start_at: Time.zone.now - 1430.minutes,
    end_at: Time.zone.now - 1429.minutes,
    duration_waiting_time: 600,
    duration_talking_time: 660,
    created_at: Time.zone.now - 1440.minutes,
  )

=end

=begin

  Cti::Log.log(current_user)

returns

  {
    list: [log_record1, log_record2, log_record3],
    assets: {...},
  }

=end

    def self.log(current_user)
      list = Cti::Log.log_records(current_user)

      # add assets
      assets = list.map(&:preferences)
                   .map { |p| p.slice(:from, :to) }
                   .map(&:values).flatten
                   .pluck(:user_id).compact
                   .map { |user_id| User.lookup(id: user_id) }.compact
                   .each.with_object({}) { |user, a| user.assets(a) }

      {
        list:   list,
        assets: assets,
      }
    end

=begin

  Cti::Log.log_records(current_user)

returns

  [log_record1, log_record2, log_record3]

=end

    def self.log_records(current_user)
      cti_config = Setting.get('cti_config')
      if cti_config[:notify_map].present?
        return Cti::Log.where(queue: queues_of_user(current_user, cti_config)).order(created_at: :desc).limit(view_limit)
      end

      Cti::Log.order(created_at: :desc).limit(view_limit)
    end

=begin

processes a incoming event

Cti::Log.process(
  cause: '',
  event: 'newCall',
  user: 'user 1',
  from: '4912347114711',
  to: '4930600000000',
  callId: '43545211', # or call_id
  direction: 'in',
  queue: 'helpdesk', # optional
)

=end

    def self.process(params)
      cause   = params['cause']
      event   = params['event']
      user    = params['user']
      queue   = params['queue']
      call_id = params['callId'] || params['call_id']
      if user.instance_of?(Array)
        user = user.join(', ')
      end

      from_comment = nil
      to_comment = nil
      preferences = nil
      done = true
      if params['direction'] == 'in'
        if user.present?
          to_comment = user
        elsif queue.present?
          to_comment = queue
        end
        from_comment, preferences = CallerId.get_comment_preferences(params['from'], 'from')
        if queue.blank?
          queue = params['to']
        end
      else
        from_comment = user
        to_comment, preferences = CallerId.get_comment_preferences(params['to'], 'to')
        if queue.blank?
          queue = params['from']
        end
      end

      log = find_by(call_id: call_id)

      case event
      when 'newCall'
        if params['direction'] == 'in'
          done = false
        end
        raise "call_id #{call_id} already exists!" if log

        log = create(
          direction:      params['direction'],
          from:           params['from'],
          from_comment:   from_comment,
          to:             params['to'],
          to_comment:     to_comment,
          call_id:        call_id,
          comment:        cause,
          queue:          queue,
          state:          event,
          initialized_at: Time.zone.now,
          preferences:    preferences,
          done:           done,
        )
      when 'answer'
        raise "No such call_id #{call_id}" if !log
        return if log.state == 'hangup' # call is already hangup, ignore answer

        log.with_lock do
          log.state = 'answer'
          log.start_at = Time.zone.now
          log.duration_waiting_time = log.start_at.to_i - log.initialized_at.to_i
          if user
            log.to_comment = user
          end
          log.done = true
          log.comment = cause
          log.save
        end
      when 'hangup'
        raise "No such call_id #{call_id}" if !log

        log.with_lock do
          log.done = done
          if params['direction'] == 'in'
            if (log.state == 'newCall' && cause != 'forwarded') || log.to_comment == 'voicemail' # rubocop:disable Style/SoleNestedConditional
              log.done = false
            end
          end
          log.state = 'hangup'
          log.end_at = Time.zone.now
          if log.start_at
            log.duration_talking_time = log.end_at.to_i - log.start_at.to_i
          elsif !log.duration_waiting_time && log.initialized_at
            log.duration_waiting_time = log.end_at.to_i - log.initialized_at.to_i
          end
          log.comment = cause
          log.save
        end
      else
        raise ArgumentError, "Unknown event #{event.inspect}"
      end

      log
    end

    def self.push_caller_list_update?(record)
      list_ids = Cti::Log.order(created_at: :desc).limit(view_limit).pluck(:id)
      return true if list_ids.include?(record.id)

      false
    end

    def push_caller_list_update
      return false if !Cti::Log.push_caller_list_update?(self)

      # send notify on create/update/delete
      users = User.with_permissions('cti.agent')
      users.each do |user|
        Sessions.send_to(
          user.id,
          {
            event: 'cti_list_push',
          },
        )
      end
      true
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
      if !from_pretty || !to_pretty
        set_pretty
      end

      virtual_attributes = {
        'from_pretty' => from_pretty,
        'to_pretty'   => to_pretty,
      }

      super.merge(virtual_attributes)
    end

    def set_pretty
      %i[from to].each do |field|
        parsed = TelephoneNumber.parse(send(field)&.sub(%r{^\+?}, '+'))
        preferences[:"#{field}_pretty"] = parsed.send(parsed.valid? ? :international_number : :original_number)
      end
    end

=begin

returns queues of user

  ['queue1', 'queue2'] = Cti::Log.queues_of_user(User.find(123), config)

=end

    def self.queues_of_user(user, config)
      queues = []
      config[:notify_map]&.each do |row|
        next if row[:user_ids].blank?
        next if row[:user_ids].exclude?(user.id.to_s) && row[:user_ids].exclude?(user.id)

        queues.push row[:queue]
      end
      if user.phone.present?
        caller_ids = Cti::CallerId.extract_numbers(user.phone)
        queues.concat(caller_ids)
      end
      queues
    end

=begin

return best customer id of caller log

  log = Cti::Log.find(123)
  customer_id = log.best_customer_id_of_log_entry

=end

    def best_customer_id_of_log_entry
      customer_id = nil
      if preferences[:from].present?
        preferences[:from].each do |entry|
          if customer_id.blank?
            customer_id = entry[:user_id]
          end
          next if entry[:level] != 'known'

          customer_id = entry[:user_id]
          break
        end
      end
      customer_id
    end

    def self.view_limit
      Hash(Setting.get('cti_config'))['view_limit'] || 60
    end
  end
end
