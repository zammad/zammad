# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class SearchIndexBackend

=begin

info about used search index machine

  SearchIndexBackend.info

=end

  def self.info
    url = Setting.get('es_url').to_s
    return if url.blank?

    Rails.logger.info "# curl -X GET \"#{url}\""
    response = UserAgent.get(
      url,
      {},
      {
        json:              true,
        open_timeout:      8,
        read_timeout:      14,
        open_socket_tries: 3,
        user:              Setting.get('es_user'),
        password:          Setting.get('es_password'),
      }
    )
    Rails.logger.info "# #{response.code}"
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
          Rails.logger.info "# curl -X DELETE \"#{url}\""
          response = UserAgent.delete(
            url,
            {
              json:              true,
              open_timeout:      8,
              read_timeout:      60,
              open_socket_tries: 3,
              user:              Setting.get('es_user'),
              password:          Setting.get('es_password'),
            }
          )
          Rails.logger.info "# #{response.code}"
          next if response.success?
          next if response.code.to_s == '404'

          raise humanized_error(
            verb:     'DELETE',
            url:      url,
            response: response,
          )
        end
        Rails.logger.info "# curl -X PUT \"#{url}\" \\"
        Rails.logger.debug { "-d '#{data.to_json}'" }
        item.delete(:action)
        response = UserAgent.put(
          url,
          item,
          {
            json:              true,
            open_timeout:      8,
            read_timeout:      60,
            open_socket_tries: 3,
            user:              Setting.get('es_user'),
            password:          Setting.get('es_password'),
          }
        )
        Rails.logger.info "# #{response.code}"
        next if response.success?

        raise humanized_error(
          verb:     'PUT',
          url:      url,
          payload:  item,
          response: response,
        )
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

    url = build_url(data[:name], nil, false, false)
    return if url.blank?

    if data[:action] && data[:action] == 'delete'
      return SearchIndexBackend.remove(data[:name])
    end

    Rails.logger.info "# curl -X PUT \"#{url}\" \\"
    Rails.logger.debug { "-d '#{data[:data].to_json}'" }

    # note that we use a high read timeout here because
    # otherwise the request will be retried (underhand)
    # which leads to an "index_already_exists_exception"
    # HTTP 400 status error
    # see: https://github.com/ankane/the-ultimate-guide-to-ruby-timeouts/issues/8
    # Improving the Elasticsearch config is probably the proper solution
    response = UserAgent.put(
      url,
      data[:data],
      {
        json:              true,
        open_timeout:      8,
        read_timeout:      60,
        open_socket_tries: 3,
        user:              Setting.get('es_user'),
        password:          Setting.get('es_password'),
      }
    )
    Rails.logger.info "# #{response.code}"
    return true if response.success?

    raise humanized_error(
      verb:     'PUT',
      url:      url,
      payload:  data[:data],
      response: response,
    )
  end

=begin

add new object to search index

  SearchIndexBackend.add('Ticket', some_data_object)

=end

  def self.add(type, data)

    url = build_url(type, data['id'])
    return if url.blank?

    Rails.logger.info "# curl -X POST \"#{url}\" \\"
    Rails.logger.debug { "-d '#{data.to_json}'" }

    response = UserAgent.post(
      url,
      data,
      {
        json:              true,
        open_timeout:      8,
        read_timeout:      60,
        open_socket_tries: 3,
        user:              Setting.get('es_user'),
        password:          Setting.get('es_password'),
      }
    )
    Rails.logger.info "# #{response.code}"
    return true if response.success?

    raise humanized_error(
      verb:     'POST',
      url:      url,
      payload:  data,
      response: response,
    )
  end

=begin

remove whole data from index

  SearchIndexBackend.remove('Ticket', 123)

  SearchIndexBackend.remove('Ticket')

=end

  def self.remove(type, o_id = nil)
    url = if o_id
            build_url(type, o_id, false, true)
          else
            build_url(type, o_id, false, false)
          end

    return if url.blank?

    Rails.logger.info "# curl -X DELETE \"#{url}\""

    response = UserAgent.delete(
      url,
      {
        open_timeout:      8,
        read_timeout:      60,
        open_socket_tries: 3,
        user:              Setting.get('es_user'),
        password:          Setting.get('es_password'),
      }
    )
    Rails.logger.info "# #{response.code}"
    return true if response.success?
    return true if response.code.to_s == '400'

    humanized_error = humanized_error(
      verb:     'DELETE',
      url:      url,
      response: response,
    )
    Rails.logger.info "NOTICE: can't delete index: #{humanized_error}"
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

    url = build_url
    return [] if url.blank?

    url += build_search_url(index)

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

    Rails.logger.info "# curl -X POST \"#{url}\" \\"
    Rails.logger.debug { " -d'#{query_data.to_json}'" }

    response = UserAgent.get(
      url,
      query_data,
      {
        json:              true,
        open_timeout:      5,
        read_timeout:      14,
        open_socket_tries: 3,
        user:              Setting.get('es_user'),
        password:          Setting.get('es_password'),
      }
    )

    Rails.logger.info "# #{response.code}"
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
      Rails.logger.info "... #{item['_type']} #{item['_id']}"

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

      # for sorting values use .raw values (no analyzer is used - plain values)
      if value !~ /\./ && value !~ /_(time|date|till|id|ids|at)$/
        value += '.raw'
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

    url = build_url(nil, nil, false, false)
    return if url.blank?

    url += build_search_url(index)

    data = selector2query(selectors, options, aggs_interval)

    Rails.logger.info "# curl -X POST \"#{url}\" \\"
    Rails.logger.debug { " -d'#{data.to_json}'" }

    response = UserAgent.get(
      url,
      data,
      {
        json:              true,
        open_timeout:      5,
        read_timeout:      14,
        open_socket_tries: 3,
        user:              Setting.get('es_user'),
        password:          Setting.get('es_password'),
      }
    )

    Rails.logger.info "# #{response.code}"
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
      return {
        count:      response.data['hits']['total'],
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

    query_must = []
    query_must_not = []
    relative_map = {
      day:    'd',
      year:   'y',
      month:  'M',
      hour:   'h',
      minute: 'm',
    }
    if selector.present?
      selector.each do |key, data|
        key_tmp = key.sub(/^.+?\./, '')
        t = {}

        # use .raw in cases where query contains ::
        if data['value'].is_a?(Array)
          data['value'].each do |value|
            if value.is_a?(String) && value =~ /::/
              key_tmp += '.raw'
              break
            end
          end
        elsif data['value'].is_a?(String)
          if /::/.match?(data['value'])
            key_tmp += '.raw'
          end
        end

        # is/is not/contains/contains not
        if data['operator'] == 'is' || data['operator'] == 'is not' || data['operator'] == 'contains' || data['operator'] == 'contains not'
          if data['value'].is_a?(Array)
            t[:terms] = {}
            t[:terms][key_tmp] = data['value']
          else
            t[:term] = {}
            t[:term][key_tmp] = data['value']
          end
          if data['operator'] == 'is' || data['operator'] == 'contains'
            query_must.push t
          elsif data['operator'] == 'is not' || data['operator'] == 'contains not'
            query_must_not.push t
          end
        elsif data['operator'] == 'contains all' || data['operator'] == 'contains one' || data['operator'] == 'contains all not' || data['operator'] == 'contains one not'
          values = data['value'].split(',').map(&:strip)
          t[:query_string] = {}
          if data['operator'] == 'contains all'
            t[:query_string][:query] = "#{key_tmp}:\"#{values.join('" AND "')}\""
            query_must.push t
          elsif data['operator'] == 'contains one not'
            t[:query_string][:query] = "#{key_tmp}:\"#{values.join('" OR "')}\""
            query_must_not.push t
          elsif data['operator'] == 'contains one'
            t[:query_string][:query] = "#{key_tmp}:\"#{values.join('" OR "')}\""
            query_must.push t
          elsif data['operator'] == 'contains all not'
            t[:query_string][:query] = "#{key_tmp}:\"#{values.join('" AND "')}\""
            query_must_not.push t
          end

        # within last/within next (relative)
        elsif data['operator'] == 'within last (relative)' || data['operator'] == 'within next (relative)'
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
        elsif data['operator'] == 'before (relative)' || data['operator'] == 'after (relative)'
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

        # before/after (absolute)
        elsif data['operator'] == 'before (absolute)' || data['operator'] == 'after (absolute)'
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

  def self.build_index_name(index)
    local_index = "#{Setting.get('es_index')}_#{Rails.env}"

    "#{local_index}_#{index.underscore.tr('/', '_')}"
  end

=begin

generate url for index or document access (only for internal use)

  # url to access single document in index (in case with_pipeline or not)
  url = SearchIndexBackend.build_url('User', 123, with_pipeline)

  # url to access whole index
  url = SearchIndexBackend.build_url('User')

  # url to access document definition in index (only es6 and higher)
  url = SearchIndexBackend.build_url('User', nil, false, true)

  # base url
  url = SearchIndexBackend.build_url

=end

  def self.build_url(type = nil, o_id = nil, with_pipeline = true, with_document_type = true)
    return if !SearchIndexBackend.enabled?

    # for elasticsearch 5.6 and lower
    index = "#{Setting.get('es_index')}_#{Rails.env}"
    if Setting.get('es_multi_index') == false
      url = Setting.get('es_url')
      url = if type
              if with_pipeline == true
                url_pipline = Setting.get('es_pipeline')
                if url_pipline.present?
                  url_pipline = "?pipeline=#{url_pipline}"
                end
              end
              if o_id
                "#{url}/#{index}/#{type}/#{o_id}#{url_pipline}"
              else
                "#{url}/#{index}/#{type}#{url_pipline}"
              end
            else
              "#{url}/#{index}"
            end
      return url
    end

    # for elasticsearch 6.x and higher
    url = Setting.get('es_url')
    if with_pipeline == true
      url_pipline = Setting.get('es_pipeline')
      if url_pipline.present?
        url_pipline = "?pipeline=#{url_pipline}"
      end
    end
    if type
      index = build_index_name(type)

      # access (e. g. creating or dropping) whole index
      if with_document_type == false
        return "#{url}/#{index}"
      end

      # access single document in index (e. g. drop or add document)
      if o_id
        return "#{url}/#{index}/_doc/#{o_id}#{url_pipline}"
      end

      # access document type (e. g. creating or dropping document mapping)
      return "#{url}/#{index}/_doc#{url_pipline}"
    end
    "#{url}/"
  end

=begin

generate url searchaccess (only for internal use)

  # url search access with single index
  url = SearchIndexBackend.build_search_url('User')

  # url to access all over es
  url = SearchIndexBackend.build_search_url

=end

  def self.build_search_url(index = nil)

    # for elasticsearch 5.6 and lower
    if Setting.get('es_multi_index') == false
      if index
        return "/#{index}/_search"
      end

      return '/_search'
    end

    # for elasticsearch 6.x and higher
    "#{build_index_name(index)}/_doc/_search"
  end

  def self.humanized_error(verb:, url:, payload: nil, response:)
    prefix = "Unable to process #{verb} request to elasticsearch URL '#{url}'."
    suffix = "\n\nResponse:\n#{response.inspect}\n\nPayload:\n#{payload.inspect}"

    if payload.respond_to?(:to_json)
      suffix += "\n\nPayload size: #{payload.to_json.bytesize / 1024 / 1024}M"
    end

    message = if response&.error&.match?('Connection refused')
                "Elasticsearch is not reachable, probably because it's not running or even installed."
              elsif url.end_with?('pipeline/zammad-attachment', 'pipeline=zammad-attachment') && response.code == 400
                'The installed attachment plugin could not handle the request payload. Ensure that the correct attachment plugin is installed (5.6 => ingest-attachment, 2.4 - 5.5 => mapper-attachments).'
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
    query += '*' if !query.match?(/:/)
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

    if (extension = options.dig(:query_extension))
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

    Rails.logger.info "# curl -X POST \"#{url}\" "

    response = UserAgent.post(
      url,
      {},
      {
        open_timeout:      8,
        read_timeout:      60,
        open_socket_tries: 3,
        user:              Setting.get('es_user'),
        password:          Setting.get('es_password'),
      }
    )

    Rails.logger.info "# #{response.code}"

    return true if response.success?

    raise humanized_error(
      verb:     'POST',
      url:      url,
      response: response,
    )
  end

end
