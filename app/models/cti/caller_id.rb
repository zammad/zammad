module Cti
  class CallerId < ApplicationModel
    self.table_name = 'cti_caller_ids'

    DEFAULT_COUNTRY_ID = '49'.freeze

    # adopt/orphan matching Cti::Log records
    # (see https://github.com/zammad/zammad/issues/2057)
    after_commit :update_cti_logs, on: :destroy
    after_commit :update_cti_logs_with_fg_optimization, on: :create

=begin

  Cti::CallerId.maybe_add(
    caller_id: '49123456789',
    comment: 'Hairdresser Bob Smith, San Francisco', #optional
    level: 'maybe', # known|maybe
    user_id: 1, # optional
    object: 'Ticket',
    o_id: 123,
  )

=end

    def self.maybe_add(data)
      record = find_or_initialize_by(
        caller_id: data[:caller_id],
        level:     data[:level],
        object:    data[:object],
        o_id:      data[:o_id],
        user_id:   data[:user_id],
      )

      return record if !record.new_record?
      record.comment = data[:comment]
      record.save!
    end

=begin

  caller_id_records = Cti::CallerId.lookup('49123456789')

returns

 [record1, record2, ...]

=end

    def self.lookup(caller_id)

      result = []
      ['known', 'maybe', nil].each do |level|

        search_params = {
          caller_id: caller_id,
        }

        if level
          search_params[:level] = level
        end

        caller_ids = Cti::CallerId.select('MAX(id) as caller_id').where(search_params).group(:user_id).order('caller_id DESC').limit(20).map(&:caller_id)
        Cti::CallerId.where(id: caller_ids).order(id: :desc).each do |record|
          result.push record
        end
        break if result.present?
      end
      result
    end

=begin

  Cti::CallerId.build(ticket)

=end

    def self.build(record)
      map = config
      level = nil
      model = nil
      map.each do |item|
        next if item[:model] != record.class
        level = item[:level]
        model = item[:model]
      end
      return if !level || !model
      build_item(record, model, level)
    end

=begin

  Cti::CallerId.build_item(record, model, level)

=end

    def self.build_item(record, model, level)

      # use first customer article
      if model == Ticket
        article = record.articles.first
        return if !article
        return if article.sender.name != 'Customer'
        record = article
      end

      # set user id
      user_id = record[:created_by_id]
      if model == User
        user_id = record.id
      end
      return if !user_id

      # get caller ids
      caller_ids = []
      attributes = record.attributes
      attributes.each_value do |value|
        next if value.class != String
        next if value.blank?
        local_caller_ids = Cti::CallerId.extract_numbers(value)
        next if local_caller_ids.blank?
        caller_ids = caller_ids.concat(local_caller_ids)
      end

      # store caller ids
      Cti::CallerId.where(object: model.to_s, o_id: record.id).destroy_all
      caller_ids.each do |caller_id|
        Cti::CallerId.maybe_add(
          caller_id: caller_id,
          level: level,
          object: model.to_s,
          o_id: record.id,
          user_id: user_id,
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
          level = item[:level]
          model = item[:model]
          item[:model].find_each(batch_size: 500) do |record|
            build_item(record, model, level)
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
      text.scan(/([\d|\s|\-|\(|\)]{6,26})/).map do |match|
        normalize_number(match[0])
      end
    end

    def self.normalize_number(number)
      number = number.gsub(/[\s-]/, '')
      number.gsub!(/^(00)?(\+?\d\d)\(0?(\d*)\)/, '\\1\\2\\3')
      number.gsub!(/\D/, '')
      case number
      when /^00/
        number[2..-1]
      when /^0/
        DEFAULT_COUNTRY_ID + number[1..-1]
      else
        number
      end
    end

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

    def update_cti_logs
      UpdateCtiLogsByCallerJob.perform_later(caller_id)
    end

    def update_cti_logs_with_fg_optimization
      UpdateCtiLogsByCallerJob.perform_now(caller_id, limit: 20)
      UpdateCtiLogsByCallerJob.perform_later(caller_id, limit: 40, offset: 20)
    end
  end
end
