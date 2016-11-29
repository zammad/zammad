module Cti
  class CallerId < ApplicationModel
    self.table_name = 'cti_caller_ids'

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
      records = Cti::CallerId.where(
        caller_id: data[:caller_id],
        level: data[:level],
        object: data[:object],
        o_id: data[:o_id],
        user_id: data[:user_id],
      )
      return if records[0]
      Cti::CallerId.create(
        caller_id: data[:caller_id],
        comment: data[:comment],
        level: data[:level],
        object: data[:object],
        o_id: data[:o_id],
        user_id: data[:user_id],
      )
    end

=begin

  caller_id_records = Cti::CallerId.lookup('49123456789')

returns

 [record1, record2, ...]

=end

    def self.lookup(caller_id)
      result = Cti::CallerId.where(
        caller_id: caller_id,
        level: 'known',
      ).group(:user_id, :id).order(id: 'DESC').limit(20)
      if !result[0]
        result = Cti::CallerId.where(
          caller_id: caller_id,
          level: 'maybe',
        ).group(:user_id, :id).order(id: 'DESC').limit(20)
      end
      if !result[0]
        result = Cti::CallerId.where(
          caller_id: caller_id,
        ).order('id DESC').limit(20)
      end

      # in case do lookups in external sources
      if !result[0]
        # ...
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
      map.each { |item|
        next if item[:model] != record.class
        level = item[:level]
        model = item[:model]
      }
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
      attributes.each { |_attribute, value|
        next if value.class != String
        next if value.empty?
        local_caller_ids = Cti::CallerId.parse_text(value)
        next if local_caller_ids.empty?
        caller_ids = caller_ids.concat(local_caller_ids)
      }

      # store caller ids
      Cti::CallerId.where(object: model.to_s, o_id: record.id).destroy_all
      caller_ids.each { |caller_id|
        Cti::CallerId.maybe_add(
          caller_id: caller_id,
          level: level,
          object: model.to_s,
          o_id: record.id,
          user_id: user_id,
        )
      }
      true
    end

=begin

  Cti::CallerId.rebuild

=end

    def self.rebuild
      Cti::CallerId.delete_all
      map = config
      map.each { |item|
        level = item[:level]
        model = item[:model]
        item[:model].find_each(batch_size: 500) do |record|
          build_item(record, model, level)
        end
      }
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

  caller_ids = Cti::CallerId.parse_text('...')

returns

  ['49123456789', '49987654321']

=end

    def self.parse_text(text)
      caller_ids = []

      # 022 1234567
      # 021 123 2345
      # 0271233211
      # 021-233-9123
      # 09 123 32112
      # 021 2331231 or 021 321123123
      # 622 32281
      # 5754321
      # 092213212
      # (09)1234321
      # +41 30 53 00 00 000
      # +42 160 0000000
      # +43 (0) 30 60 00 00 00-0
      # 0043 (0) 30 60 00 00 00-0

      default_country_id = '49'
      text.gsub!(/([\d|\s|\-|\(|\)]{6,26})/) {
        number = $1.strip
        number.sub!(/^00/, '')
        number.sub!(/\(0\)/, '')
        number.gsub!(/(\s|\-|\(|\))/, '')
        if !Phony.plausible?(number)
          if number =~ /^0/
            number.gsub!(/^0/, default_country_id)
          else
            number = "#{default_country_id}#{number}"
          end
          next if !Phony.plausible?(number)
        end
        caller_ids.push number
      }
      caller_ids
    end

    def self.get_comment_preferences(caller_id, direction)
      from_comment_known = ''
      from_comment_maybe = ''
      preferences_known = {}
      preferences_known[direction] = []
      preferences_maybe = {}
      preferences_maybe[direction] = []

      self.lookup(caller_id).each { |record|
        if record.level == 'known'
          preferences_known[direction].push record
        else
          preferences_maybe[direction].push record
        end
        comment = ''
        if record.user_id
          user = User.lookup(id: record.user_id)
          if user
            comment += user.fullname
          end
        elsif !record.comment.empty?
          comment += record.comment
        end
        if record.level == 'known'
          if !from_comment_known.empty?
            from_comment_known += ','
          end
          from_comment_known += comment
        else
          if !from_comment_maybe.empty?
            from_comment_maybe += ','
          end
          from_comment_maybe += comment
        end
      }
      return [from_comment_known, preferences_known] if !from_comment_known.empty?
      return ["maybe #{from_comment_maybe}", preferences_maybe] if !from_comment_maybe.empty?
      nil
    end

  end
end
