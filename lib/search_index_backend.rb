# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SearchIndexBackend

=begin

info about used search index machine

  SearchIndexBackend.info

=end

  def self.info
    url = Setting.get('es_url').to_s
    return if url.blank?

    response = make_request(url)

    if response.success?
      installed_version = response.data.dig('version', 'number')
      raise "Unable to get elasticsearch version from response: #{response.inspect}" if installed_version.blank?

      version_supported = Gem::Version.new(installed_version) < Gem::Version.new('8')
      raise "Version #{installed_version} of configured elasticsearch is not supported." if !version_supported

      version_supported = Gem::Version.new(installed_version) > Gem::Version.new('2.3')
      raise "Version #{installed_version} of configured elasticsearch is not supported." if !version_supported

      return response.data
    end

    raise humanized_error(
      verb:     'GET',
      url:      url,
      response: response,
    )
  end

=begin

update processors

  SearchIndexBackend.processors(
    _ingest/pipeline/attachment: {
      description: 'Extract attachment information from arrays',
      processors: [
        {
          foreach: {
            field: 'ticket.articles.attachments',
            processor: {
              attachment: {
                target_field: '_ingest._value.attachment',
                field: '_ingest._value.data'
              }
            }
          }
        }
      ]
    }
  )

=end

  def self.processors(data)
    data.each do |key, items|
      url = "#{Setting.get('es_url')}/#{key}"

      items.each do |item|
        if item[:action] == 'delete'
          response = make_request(url, method: :delete)

          next if response.success?
          next if response.code.to_s == '404'

          raise humanized_error(
            verb:     'DELETE',
            url:      url,
            response: response,
          )
        end

        item.delete(:action)

        make_request_and_validate(url, data: item, method: :put)
      end
    end
    true
  end

=begin

create/update/delete index

  SearchIndexBackend.index(
    :action => 'create',  # create/update/delete
    :name   => 'Ticket',
    :data   => {
      :mappings => {
        :Ticket => {
          :properties => {
            :articles => {
              :type       => 'nested',
              :properties => {
                'attachment' => { :type => 'attachment' }
              }
            }
          }
        }
      }
    }
  )

  SearchIndexBackend.index(
    :action => 'delete',  # create/update/delete
    :name   => 'Ticket',
  )

=end

  def self.index(data)

    url = build_url(type: data[:name], with_pipeline: false, with_document_type: false)
    return if url.blank?

    if data[:action] && data[:action] == 'delete'
      return SearchIndexBackend.remove(data[:name])
    end

    make_request_and_validate(url, data: data[:data], method: :put)
  end

=begin

add new object to search index

  SearchIndexBackend.add('Ticket', some_data_object)

=end

  def self.add(type, data)

    url = build_url(type: type, object_id: data['id'])
    return if url.blank?

    make_request_and_validate(url, data: data, method: :post)
  end

=begin

This function updates specifc attributes of an index based on a query.

  data = {
    organization: {
      name: "Zammad Foundation"
    }
  }
  where = {
    organization_id: 1
  }
  SearchIndexBackend.update_by_query('Ticket', data, where)

=end

  def self.update_by_query(type, data, where)
    return if data.blank?
    return if where.blank?

    url = build_url(type: type, action: '_update_by_query', with_pipeline: false, with_document_type: false, url_params: { conflicts: 'proceed' })
    return if url.blank?

    script_list = []
    data.each do |key, _value|
      script_list.push("ctx._source.#{key}=params.#{key}")
    end

    data = {
      script: {
        lang:   'painless',
        source: script_list.join(';'),
        params: data,
      },
      query:  {
        term: where,
      },
    }

    make_request_and_validate(url, data: data, method: :post, read_timeout: 10.minutes)
  end

=begin

remove whole data from index

  SearchIndexBackend.remove('Ticket', 123)

  SearchIndexBackend.remove('Ticket')

=end

  def self.remove(type, o_id = nil)
    url = if o_id
            build_url(type: type, object_id: o_id, with_pipeline: false, with_document_type: true)
          else
            build_url(type: type, object_id: o_id, with_pipeline: false, with_document_type: false)
          end

    return if url.blank?

    response = make_request(url, method: :delete)

    return true if response.success?
    return true if response.code.to_s == '400'

    humanized_error = humanized_error(
      verb:     'DELETE',
      url:      url,
      response: response,
    )
    Rails.logger.warn "Can't delete index: #{humanized_error}"
    false
  end

=begin

@param query   [String]  search query
@param index   [String, Array<String>] indexes to search in (see search_by_index)
@param options [Hash] search options (see build_query)

@return search result

@example Sample queries

  result = SearchIndexBackend.search('search query', ['User', 'Organization'], limit: limit)

- result = SearchIndexBackend.search('search query', 'User', limit: limit)

  result = SearchIndexBackend.search('search query', 'User', limit: limit, sort_by: ['updated_at'], order_by: ['desc'])

  result = SearchIndexBackend.search('search query', 'User', limit: limit, sort_by: ['active', updated_at'], order_by: ['desc', 'desc'])

  result = [
    {
      :id   => 123,
      :type => 'User',
    },
    {
      :id   => 125,
      :type => 'User',
    },
    {
      :id   => 15,
      :type => 'Organization',
    }
  ]

=end

  def self.search(query, index, options = {})
    if !index.is_a? Array
      return search_by_index(query, index, options)
    end

    index
      .map { |local_index| search_by_index(query, local_index, options) }
      .compact
      .flatten(1)
  end

=begin

@param query   [String] search query
@param index   [String] index name
@param options [Hash] search options (see build_query)

@return search result

=end

  def self.search_by_index(query, index, options = {})
    return [] if query.blank?

    url = build_url(type: index, action: '_search', with_pipeline: false, with_document_type: true)
    return [] if url.blank?

    # real search condition
    condition = {
      'query_string' => {
        'query'            => append_wildcard_to_simple_query(query),
        'default_operator' => 'AND',
        'analyze_wildcard' => true,
      }
    }

    if (fields = options.dig(:highlight_fields_by_indexes, index.to_sym))
      condition['query_string']['fields'] = fields
    end

    query_data = build_query(condition, options)

    if (fields = options.dig(:highlight_fields_by_indexes, index.to_sym))
      fields_for_highlight = fields.each_with_object({}) { |elem, memo| memo[elem] = {} }

      query_data[:highlight] = { fields: fields_for_highlight }
    end

    response = make_request(url, data: query_data)

    if !response.success?
      Rails.logger.error humanized_error(
        verb:     'GET',
        url:      url,
        payload:  query_data,
        response: response,
      )
      return []
    end
    data = response.data&.dig('hits', 'hits')

    return [] if !data

    data.map do |item|
      Rails.logger.debug { "... #{item['_type']} #{item['_id']}" }

      output = {
        id:   item['_id'],
        type: index,
      }

      if options.dig(:highlight_fields_by_indexes, index.to_sym)
        output[:highlight] = item['highlight']
      end

      output
    end
  end

  def self.search_by_index_sort(sort_by = nil, order_by = nil)
    result = []

    sort_by&.each_with_index do |value, index|
      next if value.blank?
      next if order_by&.at(index).blank?

      # for sorting values use .keyword values (no analyzer is used - plain values)
      if value !~ %r{\.} && value !~ %r{_(time|date|till|id|ids|at)$}
        value += '.keyword'
      end
      result.push(
        value => {
          order: order_by[index],
        },
      )
    end

    if result.blank?
      result.push(
        updated_at: {
          order: 'desc',
        },
      )
    end

    result.push('_score')

    result
  end

=begin

get count of tickets and tickets which match on selector

  result = SearchIndexBackend.selectors(index, selector)

example with a simple search:

  result = SearchIndexBackend.selectors('Ticket', { 'category' => { 'operator' => 'is', 'value' => 'aa::ab' } })

  result = [
    { id: 1, type: 'Ticket' },
    { id: 2, type: 'Ticket' },
    { id: 3, type: 'Ticket' },
  ]

you also can get aggregations

  result = SearchIndexBackend.selectors(index, selector, options, aggs_interval)

example for aggregations within one year

  aggs_interval = {
    from: '2015-01-01',
    to: '2015-12-31',
    interval: 'month', # year, quarter, month, week, day, hour, minute, second
    field: 'created_at',
  }

  options = {
    limit: 123,
    current_user: User.find(123),
  }

  result = SearchIndexBackend.selectors('Ticket', { 'category' => { 'operator' => 'is', 'value' => 'aa::ab' } }, options, aggs_interval)

  result = {
    hits:{
      total:4819,
    },
    aggregations:{
      time_buckets:{
         buckets:[
            {
               key_as_string:"2014-10-01T00:00:00.000Z",
               key:1412121600000,
               doc_count:420
            },
            {
               key_as_string:"2014-11-01T00:00:00.000Z",
               key:1414800000000,
               doc_count:561
            },
            ...
         ]
      }
    }
  }

=end

  def self.selectors(index, selectors = nil, options = {}, aggs_interval = nil)
    raise 'no selectors given' if !selectors

    url = build_url(type: index, action: '_search', with_pipeline: false, with_document_type: true)
    return if url.blank?

    data = selector2query(selectors, options, aggs_interval)

    response = make_request(url, data: data)

    if !response.success?
      raise humanized_error(
        verb:     'GET',
        url:      url,
        payload:  data,
        response: response,
      )
    end
    Rails.logger.debug { response.data.to_json }

    if aggs_interval.blank? || aggs_interval[:interval].blank?
      ticket_ids = []
      response.data['hits']['hits'].each do |item|
        ticket_ids.push item['_id']
      end

      # in lower ES 6 versions, we get total count directly, in higher
      # versions we need to pick it from total has
      count = response.data['hits']['total']
      if response.data['hits']['total'].class != Integer
        count = response.data['hits']['total']['value']
      end
      return {
        count:      count,
        ticket_ids: ticket_ids,
      }
    end
    response.data
  end

  DEFAULT_SELECTOR_OPTIONS = {
    limit: 10
  }.freeze

  def self.selector2query(selector, options, aggs_interval)
    options = DEFAULT_QUERY_OPTIONS.merge(options.deep_symbolize_keys)

    current_user = options[:current_user]
    current_user_id = UserInfo.current_user_id
    if current_user
      current_user_id = current_user.id
    end

    query_must     = []
    query_must_not = []
    relative_map   = {
      day:    'd',
      year:   'y',
      month:  'M',
      hour:   'h',
      minute: 'm',
    }
    if selector.present?
      operators_is_isnot = ['is', 'is not']

      selector.each do |key, data|

        data = data.clone
        table, key_tmp = key.split('.')
        if key_tmp.blank?
          key_tmp = table
          table   = 'ticket'
        end

        wildcard_or_term = 'term'
        if data['value'].is_a?(Array)
          wildcard_or_term = 'terms'
        end
        t = {}

        # use .keyword in case of compare exact values
        if data['operator'] == 'is' || data['operator'] == 'is not'

          case data['pre_condition']
          when 'not_set'
            data['value'] = if key_tmp.match?(%r{^(created_by|updated_by|owner|customer|user)_id})
                              1
                            end
          when 'current_user.id'
            raise "Use current_user.id in selector, but no current_user is set #{data.inspect}" if !current_user_id

            data['value']    = []
            wildcard_or_term = 'terms'

            if key_tmp == 'out_of_office_replacement_id'
              data['value'].push User.find(current_user_id).out_of_office_agent_of.pluck(:id)
            else
              data['value'].push current_user_id
            end
          when 'current_user.organization_id'
            raise "Use current_user.id in selector, but no current_user is set #{data.inspect}" if !current_user_id

            user = User.find_by(id: current_user_id)
            data['value'] = user.organization_id
          end

          if data['value'].is_a?(Array)
            data['value'].each do |value|
              next if !value.is_a?(String) || value !~ %r{[A-z]}

              key_tmp += '.keyword'
              break
            end
          elsif data['value'].is_a?(String) && %r{[A-z]}.match?(data['value'])
            key_tmp += '.keyword'
          end
        end

        # use .keyword and wildcard search in cases where query contains non A-z chars
        if data['operator'] == 'contains' || data['operator'] == 'contains not'

          if data['value'].is_a?(Array)
            data['value'].each_with_index do |value, index|
              next if !value.is_a?(String) || value !~ %r{[A-z]}

              data['value'][index] = "*#{value}*"
              key_tmp += '.keyword'
              wildcard_or_term = 'wildcards'
              break
            end
          elsif data['value'].is_a?(String) && %r{[A-z]}.match?(data['value'])
            data['value'] = "*#{data['value']}*"
            key_tmp += '.keyword'
            wildcard_or_term = 'wildcard'
          end
        end

        # for pre condition not_set we want to check if values are defined for the object by exists
        if data['pre_condition'] == 'not_set' && operators_is_isnot.include?(data['operator']) && data['value'].nil?
          t['exists'] = {
            field: key_tmp,
          }

          case data['operator']
          when 'is'
            query_must_not.push t
          when 'is not'
            query_must.push t
          end
          next

        end

        if table != 'ticket'
          key_tmp = "#{table}.#{key_tmp}"
        end

        # is/is not/contains/contains not
        case data['operator']
        when 'is', 'is not', 'contains', 'contains not'
          t[wildcard_or_term] = {}
          t[wildcard_or_term][key_tmp] = data['value']
          case data['operator']
          when 'is', 'contains'
            query_must.push t
          when 'is not', 'contains not'
            query_must_not.push t
          end
        when 'contains all', 'contains one', 'contains all not', 'contains one not'
          values = data['value'].split(',').map(&:strip)
          t[:query_string] = {}
          case data['operator']
          when 'contains all'
            t[:query_string][:query] = "#{key_tmp}:\"#{values.join('" AND "')}\""
            query_must.push t
          when 'contains one not'
            t[:query_string][:query] = "#{key_tmp}:\"#{values.join('" OR "')}\""
            query_must_not.push t
          when 'contains one'
            t[:query_string][:query] = "#{key_tmp}:\"#{values.join('" OR "')}\""
            query_must.push t
          when 'contains all not'
            t[:query_string][:query] = "#{key_tmp}:\"#{values.join('" AND "')}\""
            query_must_not.push t
          end

        # within last/within next (relative)
        when 'within last (relative)', 'within next (relative)'
          range = relative_map[data['range'].to_sym]
          if range.blank?
            raise "Invalid relative_map for range '#{data['range']}'."
          end

          t[:range] = {}
          t[:range][key_tmp] = {}
          if data['operator'] == 'within last (relative)'
            t[:range][key_tmp][:gte] = "now-#{data['value']}#{range}"
          else
            t[:range][key_tmp][:lt] = "now+#{data['value']}#{range}"
          end
          query_must.push t

        # before/after (relative)
        when 'before (relative)', 'after (relative)'
          range = relative_map[data['range'].to_sym]
          if range.blank?
            raise "Invalid relative_map for range '#{data['range']}'."
          end

          t[:range] = {}
          t[:range][key_tmp] = {}
          if data['operator'] == 'before (relative)'
            t[:range][key_tmp][:lt] = "now-#{data['value']}#{range}"
          else
            t[:range][key_tmp][:gt] = "now+#{data['value']}#{range}"
          end
          query_must.push t

        # till/from (relative)
        when 'till (relative)', 'from (relative)'
          range = relative_map[data['range'].to_sym]
          if range.blank?
            raise "Invalid relative_map for range '#{data['range']}'."
          end

          t[:range] = {}
          t[:range][key_tmp] = {}
          if data['operator'] == 'till (relative)'
            t[:range][key_tmp][:lt] = "now+#{data['value']}#{range}"
          else
            t[:range][key_tmp][:gt] = "now-#{data['value']}#{range}"
          end
          query_must.push t

        # before/after (absolute)
        when 'before (absolute)', 'after (absolute)'
          t[:range] = {}
          t[:range][key_tmp] = {}
          if data['operator'] == 'before (absolute)'
            t[:range][key_tmp][:lt] = (data['value'])
          else
            t[:range][key_tmp][:gt] = (data['value'])
          end
          query_must.push t
        else
          raise "unknown operator '#{data['operator']}' for #{key}"
        end
      end
    end
    data = {
      query: {},
      size:  options[:limit],
    }
    # add aggs to filter
    if aggs_interval.present?
      if aggs_interval[:interval].present?
        data[:size] = 0
        data[:aggs] = {
          time_buckets: {
            date_histogram: {
              field:    aggs_interval[:field],
              interval: aggs_interval[:interval],
            }
          }
        }
        if aggs_interval[:timezone].present?
          data[:aggs][:time_buckets][:date_histogram][:time_zone] = aggs_interval[:timezone]
        end
      end
      r = {}
      r[:range] = {}
      r[:range][aggs_interval[:field]] = {
        from: aggs_interval[:from],
        to:   aggs_interval[:to],
      }
      query_must.push r
    end

    data[:query][:bool] ||= {}

    if query_must.present?
      data[:query][:bool][:must] = query_must
    end
    if query_must_not.present?
      data[:query][:bool][:must_not] = query_must_not
    end

    # add sort
    if aggs_interval.present? && aggs_interval[:field].present? && aggs_interval[:interval].blank?
      sort = []
      sort[0] = {}
      sort[0][aggs_interval[:field]] = {
        order: 'desc'
      }
      sort[1] = '_score'
      data['sort'] = sort
    else
      data['sort'] = search_by_index_sort(options[:sort_by], options[:order_by])
    end

    data
  end

=begin

return true if backend is configured

  result = SearchIndexBackend.enabled?

=end

  def self.enabled?
    return false if Setting.get('es_url').blank?

    true
  end

  def self.build_index_name(index = nil)
    local_index = "#{Setting.get('es_index')}_#{Rails.env}"
    return local_index if index.blank?

    "#{local_index}_#{index.underscore.tr('/', '_')}"
  end

=begin

generate url for index or document access (only for internal use)

  # url to access single document in index (in case with_pipeline or not)
  url = SearchIndexBackend.build_url(type: 'User', object_id: 123, with_pipeline: true)

  # url to access whole index
  url = SearchIndexBackend.build_url(type: 'User')

  # url to access document definition in index (only es6 and higher)
  url = SearchIndexBackend.build_url(type: 'User', with_pipeline: false, with_document_type: true)

  # base url
  url = SearchIndexBackend.build_url

=end

  # rubocop:disable Metrics/ParameterLists
  def self.build_url(type: nil, action: nil, object_id: nil, with_pipeline: true, with_document_type: true, url_params: {})
    # rubocop:enable  Metrics/ParameterLists
    return if !SearchIndexBackend.enabled?

    # set index
    index = build_index_name(type)

    # add pipeline if needed
    if index && with_pipeline == true
      url_pipline = Setting.get('es_pipeline')
      if url_pipline.present?
        url_params['pipeline'] = url_pipline
      end
    end

    # prepare url params
    params_string = ''
    if url_params.present?
      params_string = "?#{URI.encode_www_form(url_params)}"
    end

    url = Setting.get('es_url')
    return "#{url}#{params_string}" if index.blank?

    # add type information
    url = "#{url}/#{index}"

    # add document type
    if with_document_type
      url = "#{url}/_doc"
    end

    # add action
    if action
      url = "#{url}/#{action}"
    end

    # add object id
    if object_id.present?
      url = "#{url}/#{object_id}"
    end

    "#{url}#{params_string}"
  end

  def self.humanized_error(verb:, url:, response:, payload: nil)
    prefix = "Unable to process #{verb} request to elasticsearch URL '#{url}'."
    suffix = "\n\nResponse:\n#{response.inspect}\n\n"

    if payload.respond_to?(:to_json)
      suffix += "Payload:\n#{payload.to_json}"
      suffix += "\n\nPayload size: #{payload.to_json.bytesize / 1024 / 1024}M"
    else
      suffix += "Payload:\n#{payload.inspect}"
    end

    message = if response&.error&.match?('Connection refused')
                "Elasticsearch is not reachable, probably because it's not running or even installed."
              elsif url.end_with?('pipeline/zammad-attachment', 'pipeline=zammad-attachment') && response.code == 400
                'The installed attachment plugin could not handle the request payload. Ensure that the correct attachment plugin is installed (ingest-attachment).'
              else
                'Check the response and payload for detailed information: '
              end

    result = "#{prefix} #{message}#{suffix}"
    Rails.logger.error result.first(40_000)
    result
  end

  # add * on simple query like "somephrase23"
  def self.append_wildcard_to_simple_query(query)
    query.strip!
    query += '*' if query.exclude?(':')
    query
  end

=begin

@param condition [Hash] search condition
@param options [Hash] search options
@option options [Integer] :from
@option options [Integer] :limit
@option options [Hash] :query_extension applied to ElasticSearch query
@option options [Array<String>] :order_by ordering directions, desc or asc
@option options [Array<String>] :sort_by fields to sort by

=end

  DEFAULT_QUERY_OPTIONS = {
    from:  0,
    limit: 10
  }.freeze

  def self.build_query(condition, options = {})
    options = DEFAULT_QUERY_OPTIONS.merge(options.deep_symbolize_keys)

    data = {
      from:  options[:from],
      size:  options[:limit],
      sort:  search_by_index_sort(options[:sort_by], options[:order_by]),
      query: {
        bool: {
          must: []
        }
      }
    }

    if (extension = options[:query_extension])
      data[:query].deep_merge! extension.deep_dup
    end

    data[:query][:bool][:must].push condition

    data
  end

=begin

refreshes all indexes to make previous request data visible in future requests

  SearchIndexBackend.refresh

=end

  def self.refresh
    return if !enabled?

    url = "#{Setting.get('es_url')}/_all/_refresh"

    make_request_and_validate(url, method: :post)
  end

=begin

helper method for making HTTP calls

@param url [String] url
@option params [Hash] :data is a payload hash
@option params [Symbol] :method is a HTTP method
@option params [Integer] :open_timeout is HTTP request open timeout
@option params [Integer] :read_timeout is HTTP request read timeout

@return UserAgent response

=end
  def self.make_request(url, data: {}, method: :get, open_timeout: 8, read_timeout: 180)
    Rails.logger.debug { "# curl -X #{method} \"#{url}\" " }
    Rails.logger.debug { "-d '#{data.to_json}'" } if data.present?

    options = {
      json:              true,
      open_timeout:      open_timeout,
      read_timeout:      read_timeout,
      total_timeout:     (open_timeout + read_timeout + 60),
      open_socket_tries: 3,
      user:              Setting.get('es_user'),
      password:          Setting.get('es_password'),
    }

    response = UserAgent.send(method, url, data, options)

    Rails.logger.debug { "# #{response.code}" }

    response
  end

=begin

helper method for making HTTP calls and raising error if response was not success

@param url [String] url
@option args [Hash] see {make_request}

@return [Boolean] always returns true. Raises error if something went wrong.

=end

  def self.make_request_and_validate(url, **args)
    response = make_request(url, args)

    return true if response.success?

    raise humanized_error(
      verb:     args[:method],
      url:      url,
      payload:  args[:data],
      response: response
    )
  end

=begin

  This function will return a index mapping based on the
  attributes of the database table of the existing object.

  mapping = SearchIndexBackend.get_mapping_properties_object(Ticket)

  Returns:

  mapping = {
    User: {
      properties: {
        firstname: {
          type: 'keyword',
        },
      }
    }
  }

=end

  def self.get_mapping_properties_object(object)
    name = '_doc'
    result = {
      name => {
        properties: {}
      }
    }

    store_columns = %w[preferences data]

    # for elasticsearch 6.x and later
    string_type = 'text'
    string_raw  = { type: 'keyword', ignore_above: 5012 }
    boolean_raw = { type: 'boolean' }

    object.columns_hash.each do |key, value|
      if value.type == :string && value.limit && value.limit <= 5000 && store_columns.exclude?(key)
        result[name][:properties][key] = {
          type:   string_type,
          fields: {
            keyword: string_raw,
          }
        }
      elsif value.type == :integer
        result[name][:properties][key] = {
          type: 'integer',
        }
      elsif value.type == :datetime || value.type == :date
        result[name][:properties][key] = {
          type: 'date',
        }
      elsif value.type == :boolean
        result[name][:properties][key] = {
          type:   'boolean',
          fields: {
            keyword: boolean_raw,
          }
        }
      elsif value.type == :binary
        result[name][:properties][key] = {
          type: 'binary',
        }
      elsif value.type == :bigint
        result[name][:properties][key] = {
          type: 'long',
        }
      elsif value.type == :decimal
        result[name][:properties][key] = {
          type: 'float',
        }
      end
    end

    case object.name
    when 'Ticket'
      result[name][:_source] = {
        excludes: ['article.attachment']
      }
      result[name][:properties][:article] = {
        type:              'nested',
        include_in_parent: true,
      }
    when 'KnowledgeBase::Answer::Translation'
      result[name][:_source] = {
        excludes: ['attachment']
      }
    end

    return result if type_in_mapping?

    result[name]
  end

  # get es version
  def self.version
    @version ||= begin
      info = SearchIndexBackend.info
      number = nil
      if info.present?
        number = info['version']['number'].to_s
      end
      number
    end
  end

  def self.version_int
    number = version
    return 0 if !number

    number_split = version.split('.')
    "#{number_split[0]}#{format('%<minor>03d', minor: number_split[1])}#{format('%<patch>03d', patch: number_split[2])}".to_i
  end

  def self.version_supported?

    # only versions greater/equal than 6.5.0 are supported
    return if version_int < 6_005_000

    true
  end

  # no type in mapping
  def self.type_in_mapping?
    return true if version_int < 7_000_000

    false
  end

  # is es configured?
  def self.configured?
    return false if Setting.get('es_url').blank?

    true
  end

  def self.settings
    {
      'index.mapping.total_fields.limit': 2000,
    }
  end

  def self.create_index(models = Models.indexable)
    models.each do |local_object|
      SearchIndexBackend.index(
        action: 'create',
        name:   local_object.name,
        data:   {
          mappings: SearchIndexBackend.get_mapping_properties_object(local_object),
          settings: SearchIndexBackend.settings,
        }
      )
    end
  end

  def self.drop_index(models = Models.indexable)
    models.each do |local_object|
      SearchIndexBackend.index(
        action: 'delete',
        name:   local_object.name,
      )
    end
  end

  def self.create_object_index(object)
    models = Models.indexable.select { |c| c.to_s == object }
    create_index(models)
  end

  def self.drop_object_index(object)
    models = Models.indexable.select { |c| c.to_s == object }
    drop_index(models)
  end

  def self.pipeline(create: false)
    pipeline = Setting.get('es_pipeline')
    if create && pipeline.blank?
      pipeline = "zammad#{rand(999_999_999_999)}"
      Setting.set('es_pipeline', pipeline)
    end
    pipeline
  end

  def self.pipeline_settings
    {
      ignore_failure: true,
      ignore_missing: true,
    }
  end

  def self.create_pipeline
    SearchIndexBackend.processors(
      "_ingest/pipeline/#{pipeline(create: true)}": [
        {
          action: 'delete',
        },
        {
          action:      'create',
          description: 'Extract zammad-attachment information from arrays',
          processors:  [
            {
              foreach: {
                field:     'article',
                processor: {
                  foreach: {
                    field:     '_ingest._value.attachment',
                    processor: {
                      attachment: {
                        target_field: '_ingest._value',
                        field:        '_ingest._value._content',
                      }.merge(pipeline_settings),
                    }
                  }.merge(pipeline_settings),
                }
              }.merge(pipeline_settings),
            },
            {
              foreach: {
                field:     'attachment',
                processor: {
                  attachment: {
                    target_field: '_ingest._value',
                    field:        '_ingest._value._content',
                  }.merge(pipeline_settings),
                }
              }.merge(pipeline_settings),
            }
          ]
        }
      ]
    )
  end

  def self.drop_pipeline
    return if pipeline.blank?

    SearchIndexBackend.processors(
      "_ingest/pipeline/#{pipeline}": [
        {
          action: 'delete',
        },
      ]
    )
  end

end
