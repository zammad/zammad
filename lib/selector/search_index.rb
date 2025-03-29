# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Selector::SearchIndex < Selector::Base
  def get
    result = {
      size: options[:limit] || SearchIndexBackend::DEFAULT_QUERY_OPTIONS[:limit],
    }

    query = run(selector, 0)
    if query.present?
      result[:query] = query
    end

    result = query_aggs_range(result)
    query_sort(result)

  end

  def query_sort(query)
    if options[:aggs_interval].present? && options[:aggs_interval][:field].present? && options[:aggs_interval][:interval].blank?
      query_sort_by_aggs_interval(query)
    else
      query_sort_by_index(query)
    end
    query
  end

  def query_sort_by_index(query)
    query[:sort] = SearchIndexBackend.search_by_index_sort(index: target_class.to_s, sort_by: options[:sort_by], order_by: options[:order_by])
    query
  end

  def query_sort_by_aggs_interval(query)
    query[:sort] = [
      {
        options[:aggs_interval][:field] => {
          order: 'desc',
        }
      },
      '_score'
    ]
    query
  end

  def query_aggs_range(query)
    return query if options[:aggs_interval].blank?

    query = query_aggs_interval(query)

    query[:query] = {
      bool: {
        must: [
          {
            range: {
              options[:aggs_interval][:field] => {
                from: options[:aggs_interval][:from],
                to:   options[:aggs_interval][:to],
              },
            },
          },
          query[:query],
        ],
      },
    }

    query
  end

  def query_aggs_interval(query)
    return query if options[:aggs_interval][:interval].blank?

    query[:size] = 0
    query[:aggs] = {
      time_buckets: {
        date_histogram: {
          field:             options[:aggs_interval][:field],
          calendar_interval: options[:aggs_interval][:interval],
        }
      }
    }

    query_aggs_interval_timezone(query)

  end

  def query_aggs_interval_timezone(query)
    return query if options[:aggs_interval][:timezone].blank?

    query[:aggs][:time_buckets][:date_histogram][:time_zone] = options[:aggs_interval][:timezone]

    query
  end

  def run(block, level)
    if block.key?(:conditions)
      block_query = block[:conditions].map do |sub_block|
        run(sub_block, level + 1)
      end

      block_query = block_query.compact
      return if block_query.blank?

      operator = :must
      case block[:operator]
      when 'NOT'
        operator = :must_not
      when 'OR'
        operator = :should
      end

      {
        bool: {
          operator => block_query
        }
      }
    else
      condition_query(block)
    end
  end

  def condition_query(block_condition)
    query_must     = []
    query_must_not = []

    current_user = options[:current_user]
    current_user_id = UserInfo.current_user_id
    if current_user
      current_user_id = current_user.id
    end

    relative_map = {
      day:    'd',
      year:   'y',
      month:  'M',
      week:   'w',
      hour:   'h',
      minute: 'm',
    }

    operators_is_isnot = ['is', 'is not']

    data           = block_condition.clone
    key            = data[:name]
    table, key_tmp = key.split('.')
    if key_tmp.blank?
      key_tmp = table
      table   = target_name
    end

    wildcard_or_term = 'term'
    if data[:value].is_a?(Array)
      wildcard_or_term = 'terms'
    end
    t = {}

    # use .keyword in case of compare exact values
    if ['is', 'is not', 'is any of', 'is none of', 'starts with one of', 'ends with one of'].include?(data[:operator])

      case data[:pre_condition]
      when 'not_set'
        wildcard_or_term = 'term'
        data[:value] = if key_tmp.match?(%r{^(created_by|updated_by|owner|customer|user)_id})
                         1
                       end
      when 'current_user.id'
        raise "Use current_user.id in selector, but no current_user is set #{data.inspect}" if !current_user_id

        data[:value] = []
        wildcard_or_term = 'terms'

        if key_tmp == 'out_of_office_replacement_id'
          data[:value].push User.find(current_user_id).out_of_office_agent_of.pluck(:id)
        else
          data[:value].push current_user_id
        end
      when 'current_user.organization_id'
        raise "Use current_user.id in selector, but no current_user is set #{data.inspect}" if !current_user_id

        wildcard_or_term = 'term'
        user = User.find_by(id: current_user_id)
        data[:value] = user.organization_id
      end

      if data[:value].is_a?(Array)
        data[:value].each do |value|
          next if !value.is_a?(String) || value !~ %r{[A-z]}

          key_tmp += '.keyword'
          break
        end
      elsif data[:value].is_a?(String) && %r{[A-z]}.match?(data[:value])
        key_tmp += '.keyword'
      end
    end

    # use .keyword and wildcard search in cases where query contains non A-z chars
    value_is_string = Array.wrap(data[:value]).any? { |v| v.is_a?(String) && v.match?(%r{[A-z]}) }
    if ['contains', 'contains not', 'starts with one of', 'ends with one of'].include?(data[:operator]) && value_is_string
      wildcard_or_term = 'wildcard'
      if !key_tmp.ends_with?('.keyword')
        key_tmp += '.keyword'
      end

      if data[:value].is_a?(Array)
        or_condition = {
          bool: {
            should: [],
          }
        }

        data[:value].each do |value|
          t = {}
          t[wildcard_or_term] = {}
          t[wildcard_or_term][key_tmp] = if data[:operator] == 'starts with one of'
                                           "#{value}*"
                                         elsif data[:operator] == 'ends with one of'
                                           "*#{value}"
                                         else
                                           "*#{value}*"
                                         end

          or_condition[:bool][:should] << t
        end

        data[:value] = or_condition
      else
        data[:value] = "*#{data[:value]}*"
      end
    end

    if table != target_name
      key_tmp = "#{table}.#{key_tmp}"
    end

    # for pre condition not_set we want to check if values are defined for the object by exists
    if operators_is_isnot.include?(data[:operator]) && data[:value].nil?
      t['exists'] = {
        field: key_tmp,
      }

      case data[:operator]
      when 'is'
        query_must_not.push t
      when 'is not'
        query_must.push t
      end

    elsif data[:value].is_a?(Hash) && data[:value][:bool].present?
      query_must.push data[:value]

    # is/is not/contains/contains not
    elsif ['is', 'is not', 'contains', 'contains not', 'is any of', 'is none of'].include?(data[:operator])
      t[wildcard_or_term] = {}

      # We need a special handling for external data sources, because of the sub-hash.
      # Because of the automatic field map detection of ES, we need to use the integer or string way.
      # This can currently lead to a not working condition (when ES detected the wrong data type, can normally be fixed with a reindex).
      if (data[:value].is_a?(Array) && data[:value][0].is_a?(Hash)) || data[:value].is_a?(Hash)
        key_value = "#{key_tmp}.value"
        if (data[:value].is_a?(Hash) && data[:value][:value].is_a?(String)) || (data[:value].is_a?(Array) && data[:value].any? { |item| item[:value].is_a?(String) })
          key_value += '.keyword'
        end

        t[wildcard_or_term][key_value] = data[:value].is_a?(Hash) ? data[:value][:value] : data[:value].pluck(:value)
      else
        t[wildcard_or_term][key_tmp] = data[:value]
      end

      case data[:operator]
      when 'is', 'contains', 'is any of'
        query_must.push t
      when 'is not', 'contains not', 'is none of'
        query_must_not.push t
      end
    elsif ['contains all', 'contains one', 'contains all not', 'contains one not'].include?(data[:operator])
      values = data[:value]
      if data[:value].is_a?(String)
        values = values.split(',').map(&:strip)
      end

      t[:query_string] = {}
      case data[:operator]
      when 'contains all'
        t[:query_string][:query] = "#{key_tmp}:(\"#{values.join('" AND "')}\")"
        query_must.push t
      when 'contains one not'
        t[:query_string][:query] = "#{key_tmp}:(\"#{values.join('" OR "')}\")"
        query_must_not.push t
      when 'contains one'
        t[:query_string][:query] = "#{key_tmp}:(\"#{values.join('" OR "')}\")"
        query_must.push t
      when 'contains all not'
        t[:query_string][:query] = "#{key_tmp}:(\"#{values.join('" AND "')}\")"
        query_must_not.push t
      end

    # is less/greater than
    elsif ['is less than', 'is greater than'].include?(data[:operator])
      t[:range] = {}
      t[:range][key_tmp] = {}
      if data[:operator] == 'is less than'
        t[:range][key_tmp][:lt] = data[:value]
      else
        t[:range][key_tmp][:gt] = data[:value]
      end
      query_must.push t

    # within last/within next (relative)
    elsif ['within last (relative)', 'within next (relative)'].include?(data[:operator])
      range = relative_map[data[:range].to_sym]
      if range.blank?
        raise "Invalid relative_map for range '#{data[:range]}'."
      end

      t[:range] = {}
      t[:range][key_tmp] = {}
      if data[:operator] == 'within last (relative)'
        t[:range][key_tmp][:gte] = "now-#{data[:value]}#{range}"
      else
        t[:range][key_tmp][:lt] = "now+#{data[:value]}#{range}"
      end
      query_must.push t

    # before/after (relative)
    elsif ['before (relative)', 'after (relative)'].include?(data[:operator])
      range = relative_map[data[:range].to_sym]
      if range.blank?
        raise "Invalid relative_map for range '#{data[:range]}'."
      end

      t[:range] = {}
      t[:range][key_tmp] = {}
      if data[:operator] == 'before (relative)'
        t[:range][key_tmp][:lt] = "now-#{data[:value]}#{range}"
      else
        t[:range][key_tmp][:gt] = "now+#{data[:value]}#{range}"
      end
      query_must.push t

    # till/from (relative)
    elsif ['till (relative)', 'from (relative)'].include?(data[:operator])
      range = relative_map[data[:range].to_sym]
      if range.blank?
        raise "Invalid relative_map for range '#{data[:range]}'."
      end

      t[:range] = {}
      t[:range][key_tmp] = {}
      if data[:operator] == 'till (relative)'
        t[:range][key_tmp][:lt] = "now+#{data[:value]}#{range}"
      else
        t[:range][key_tmp][:gt] = "now-#{data[:value]}#{range}"
      end
      query_must.push t

    # before/after (absolute)
    elsif ['before (absolute)', 'after (absolute)'].include?(data[:operator])
      t[:range] = {}
      t[:range][key_tmp] = {}
      if data[:operator] == 'before (absolute)'
        t[:range][key_tmp][:lt] = data[:value]
      else
        t[:range][key_tmp][:gt] = data[:value]
      end
      query_must.push t
    elsif data[:operator] == 'today'
      t[:range]                = {}
      t[:range][key_tmp]       = {}
      t[:range][key_tmp][:gte] = "#{Time.zone.today}T00:00:00Z"
      t[:range][key_tmp][:lte] = "#{Time.zone.today}T23:59:59Z"
      query_must.push t
    else
      raise "unknown operator '#{data[:operator]}' for #{key}"
    end

    data = {
      bool: {},
    }

    if query_must.present?
      data[:bool][:must] = query_must
    end
    if query_must_not.present?
      data[:bool][:must_not] = query_must_not
    end

    data
  end
end
