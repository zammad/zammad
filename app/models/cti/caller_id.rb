# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Cti
  class CallerId < ApplicationModel
    self.table_name = 'cti_caller_ids'

    DEFAULT_COUNTRY_ID = '49'.freeze

    # adopt/orphan matching Cti::Log records
    # (see https://github.com/zammad/zammad/issues/2057)
    after_commit :update_cti_logs, on: :destroy, unless: -> { BulkImportInfo.enabled? }
    after_commit :update_cti_logs_with_fg_optimization, on: :create, unless: -> { BulkImportInfo.enabled? }

=begin

get items (users) for a certain caller ID

  caller_id_records = Cti::CallerId.lookup('49123456789')

returns

 [record1, record2, ...]

=end

    def self.lookup(caller_id)
      lookup_ids =
        ['known', 'maybe', nil].lazy.map do |level|
          Cti::CallerId.select('MAX(id) as caller_id')
                       .where({ caller_id: caller_id, level: level }.compact)
                       .group(:user_id)
                       .reorder(Arel.sql('caller_id DESC')) # not used as `caller_id: :desc` because is needed for `as caller_id`
                       .limit(20)
                       .map(&:caller_id)
        end.find(&:present?)

      Cti::CallerId.where(id: lookup_ids).reorder(id: :desc).to_a
    end

=begin

  Cti::CallerId.add(record)

=end

    def self.add(record)
      model = record.class.to_s
      level = config.find { |item| item[:model] == record.class }&.dig(:level)

      # use first customer article
      if record.instance_of?(Ticket)
        article = record.articles.first
        return if !article
        return if article.sender.name != 'Customer'

        record = article
      end

      # set user id
      user_id = record[:created_by_id]
      if record.instance_of?(User)
        if record.destroyed?
          Cti::CallerId.where(user_id: user_id).destroy_all
          return
        end
        user_id = record.id
      end
      return if !user_id

      # get caller IDs
      caller_ids = []
      attributes = record.attributes
      attributes.each_value do |value|
        next if value.class != String
        next if value.blank?

        local_caller_ids = Cti::CallerId.extract_numbers(value)
        next if local_caller_ids.blank?

        caller_ids.concat(local_caller_ids)
      end

      # search for caller IDs to keep
      caller_ids_to_add = []
      existing_record_ids = Cti::CallerId.where(object: model, o_id: record.id).pluck(:id)
      caller_ids.uniq.each do |caller_id|
        existing_record_id = Cti::CallerId.where(
          object:    model,
          o_id:      record.id,
          caller_id: caller_id,
          level:     level,
          user_id:   user_id,
        ).pluck(:id)
        if existing_record_id[0]
          existing_record_ids.delete(existing_record_id[0])
          next
        end
        caller_ids_to_add.push caller_id
      end

      # delete not longer existing caller IDs
      existing_record_ids.each do |record_id|
        Cti::CallerId.destroy(record_id)
      end

      # create new caller IDs
      caller_ids_to_add.each do |caller_id|
        Cti::CallerId.create!(
          caller_id: caller_id,
          level:     level,
          object:    model,
          o_id:      record.id,
          user_id:   user_id,
        )
      end
      true
    end

=begin

  Cti::CallerId.rebuild

=end

    def self.rebuild
      transaction do
        delete_all
        config.each do |item|
          item[:model].find_each(batch_size: 500) do |record|
            add(record)
          end
        end
      end
    end

=begin

  Cti::CallerId.config

returns

  [
    {
      model: User,
      level: 'known',
    },
    {
      model: Ticket,
      level: 'maybe',
    },
  ]

=end

    def self.config
      [
        {
          model: User,
          level: 'known',
        },
        {
          model: Ticket,
          level: 'maybe',
        },
      ]
    end

=begin

  caller_ids = Cti::CallerId.extract_numbers('...')

returns

  ['49123456789', '49987654321']

=end

    def self.extract_numbers(text)
      # see specs for example
      return [] if !text.is_a?(String)

      text.scan(%r{([\d\s\-(|)]{6,26})}).map do |match|
        normalize_number(match[0])
      end
    end

    def self.normalize_number(number)
      number = number.gsub(%r{[\s-]}, '')
      number.gsub!(%r{^(00)?(\+?\d\d)\(0?(\d*)\)}, '\\1\\2\\3')
      number.gsub!(%r{\D}, '')
      case number
      when %r{^00}
        number[2..]
      when %r{^0}
        DEFAULT_COUNTRY_ID + number[1..]
      else
        number
      end
    end

=begin

  from_comment, preferences = Cti::CallerId.get_comment_preferences('00491710000000', 'from')

  returns

  [
    "Bob Smith",
    {
      "from"=>[
        {
          "id"=>1961634,
          "caller_id"=>"491710000000",
          "comment"=>nil,
          "level"=>"known",
          "object"=>"User",
          "o_id"=>3,
          "user_id"=>3,
          "preferences"=>nil,
          "created_at"=>Mon, 24 Sep 2018 15:19:48 UTC +00:00,
          "updated_at"=>Mon, 24 Sep 2018 15:19:48 UTC +00:00,
        }
      ]
    }
  ]

=end

    def self.get_comment_preferences(caller_id, direction)
      from_comment_known = ''
      from_comment_maybe = ''
      preferences_known = {}
      preferences_known[direction] = []
      preferences_maybe = {}
      preferences_maybe[direction] = []

      lookup(extract_numbers(caller_id)).each do |record|
        if record.level == 'known'
          preferences_known[direction].push record.attributes
        else
          preferences_maybe[direction].push record.attributes
        end
        comment = ''
        if record.user_id
          user = User.lookup(id: record.user_id)
          if user
            comment += user.fullname
          end
        elsif record.comment.present?
          comment += record.comment
        end
        if record.level == 'known'
          if from_comment_known.present?
            from_comment_known += ','
          end
          from_comment_known += comment
        else
          if from_comment_maybe.present?
            from_comment_maybe += ','
          end
          from_comment_maybe += comment
        end
      end
      return [from_comment_known, preferences_known] if from_comment_known.present?
      return ["maybe #{from_comment_maybe}", preferences_maybe] if from_comment_maybe.present?

      nil
    end

=begin

return users by caller_id

  [user1, user2] = Cti::CallerId.known_agents_by_number('491234567')

=end

    def self.known_agents_by_number(number)
      users = []
      caller_ids = Cti::CallerId.extract_numbers(number)
      caller_id_records = Cti::CallerId.lookup(caller_ids)
      caller_id_records.each do |caller_id_record|
        next if caller_id_record.level != 'known'

        user = User.find_by(id: caller_id_record.user_id)
        next if !user
        next if !user.permissions?('cti.agent')

        users.push user
      end
      users
    end

    def update_cti_logs
      return if object != 'User'

      UpdateCtiLogsByCallerJob.perform_later(caller_id)
    end

    def update_cti_logs_with_fg_optimization
      return if Setting.get('import_mode')
      return if object != 'User'
      return if level != 'known'

      UpdateCtiLogsByCallerJob.perform_now(caller_id, limit: 20)
      UpdateCtiLogsByCallerJob.perform_later(caller_id, limit: 40, offset: 20)
    end
  end
end
