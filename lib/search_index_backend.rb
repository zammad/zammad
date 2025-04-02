# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SearchIndexBackend

  SUPPORTED_ES_VERSION_MINIMUM   = '7.8'.freeze
  SUPPORTED_ES_VERSION_LESS_THAN = '9'.freeze

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

      installed_version_parsed = Gem::Version.new(installed_version)

      if (installed_version_parsed >= Gem::Version.new(SUPPORTED_ES_VERSION_LESS_THAN)) ||
         (installed_version_parsed < Gem::Version.new(SUPPORTED_ES_VERSION_MINIMUM))
        raise "Version #{installed_version} of configured elasticsearch is not supported."
      end

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
      return if !SearchIndexBackend.index_exists?(data[:name])

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

get object of search index by id

  SearchIndexBackend.get('Ticket', 123)

=end

  def self.get(type, data)

    url = build_url(type: type, object_id: data, with_pipeline: false)
    return if url.blank?

    make_request(url, method: :get).try(:data)
  end

=begin

Check if an index exists.

  SearchIndexBackend.index_exists?('Ticket')

=end

  def self.index_exists?(type)
    url = build_url(type: type, with_pipeline: false, with_document_type: false)
    return if url.blank?

    response = make_request(url)
    return true if response.success?
    return true if response.code.to_s != '404'

    false
  end

=begin

This function updates specifc attributes of an index based on a query.
It should get used in batches to prevent performance issues on entities which have millions of objects in it.

  data = {
    organization: {
      name: "Zammad Foundation"
    }
  }
  where = {
    term: {
      organization_id: 1
    }
  }
  SearchIndexBackend.update_by_query('Ticket', data, where)

=end

  def self.update_by_query(type, data, where)
    return if data.blank?
    return if where.blank?

    url_params = {
      conflicts: 'proceed',
      slices:    'auto',
      max_docs:  1_000,
    }
    url = build_url(type: type, action: '_update_by_query', with_pipeline: false, with_document_type: false, url_params: url_params)
    return if url.blank?

    script_list = []
    data.each_key do |key|
      script_list.push("ctx._source.#{key}=params.#{key}")
    end

    data = {
      script: {
        lang:   'painless',
        source: script_list.join(';'),
        params: data,
      },
      query:  where,
      sort:   {
        id: 'desc',
      },
    }

    response = make_request(url, data: data, method: :post, read_timeout: 10.minutes)
    if !response.success?
      Rails.logger.error humanized_error(
        verb:     'GET',
        url:      url,
        payload:  data,
        response: response,
      )
      return []
    end

    response.data
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

  result = SearchIndexBackend.search('Nicole', 'User', only_total_count: true)

  { :total_count => 1 }

=end

  def self.search(query, index, options = {})
    if options.key? :with_total_count
      raise 'Option "with_total_count" is not supported by multi-index search. Please use search_by_index instead.' # rubocop:disable Zammad/DetectTranslatableString
    end

    if !index.is_a? Array
      return search_by_index(query, index, options)
    end

    index
      .filter_map { |local_index| search_by_index(query, local_index, options) }
      .flatten(1)
  end

=begin

@param query   [String] search query
@param index   [String] index name
@param options [Hash] search options (see build_query)

@return search result

  result = SearchIndexBackend.search_by_index('Nicole', 'User', only_total_count: true)

  { :total_count => 1 }

  result = SearchIndexBackend.search_by_index('Nicole', 'User', with_total_count: true)

  {
    :total_count => 1,
    :object_metadata => [
      {
        :id => "2",
        :type => "User"
      }
    ]
  }

  result = SearchIndexBackend.search_by_index('Nicole', 'User')

  [
    {
      :id => "2",
      :type => "User"
    }
  ]

=end

  def self.search_by_index(query, index, options = {})
    return if query.blank?

    action = '_search'
    if options[:only_total_count].present?
      action = '_count'
    end

    url = build_url(type: index, action: action, with_pipeline: false, with_document_type: false)
    return if url.blank?

    # real search condition
    condition = {
      'query_string' => {
        'query'            => append_wildcard_to_simple_query(query),
        'time_zone'        => Setting.get('timezone_default'),
        'default_operator' => 'AND',
        'analyze_wildcard' => true,
      }
    }

    if (fields = options.dig(:query_fields_by_indexes, index.to_sym))
      condition['query_string']['fields'] = fields
    end

    query_data = build_query(index, condition, options)

    if (fields = options.dig(:highlight_fields_by_indexes, index.to_sym)) && options[:only_total_count].blank?
      fields_for_highlight = fields.index_with { |_elem| {} }

      query_data[:highlight] = { fields: fields_for_highlight }
    end

    if options[:only_total_count].present?
      query_data.slice!(:query)
    end

    response = make_request(url, data: query_data, method: :post)

    if options[:only_total_count].present?
      return {
        total_count: response.data&.dig('count') || 0,
      }
    end

    data = if response.success?
             Array.wrap(response.data&.dig('hits', 'hits'))
           else
             Rails.logger.error humanized_error(
               verb:     'GET',
               url:      url,
               payload:  query_data,
               response: response,
             )
             []
           end

    data.map! do |item|
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

    if options[:with_total_count].present?
      return {
        total_count:     response.data&.dig('hits', 'total', 'value') || 0,
        object_metadata: data,
      }
    end

    data
  end

  def self.search_by_index_sort(index:, sort_by: nil, order_by: nil, fulltext: false)
    result = (sort_by || [])
      .map(&:to_s)
      .each_with_object([])
      .with_index do |(elem, memo), idx|
        next if elem.blank?
        next if order_by&.at(idx).blank?

        # for sorting values use .keyword values (no analyzer is used - plain values)
        is_keyword = get_mapping_properties_object(Array.wrap(index).first.constantize).dig(:properties, elem, :fields, :keyword, :type) == 'keyword'
        if is_keyword
          elem += '.keyword'
        end

        memo.push(
          elem => {
            order: order_by[idx],
          },
        )
      end

    # if we have no fulltext search then the primary default sort is updated at else score
    if result.blank? && !fulltext
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

    url = build_url(type: index, action: '_search', with_pipeline: false, with_document_type: false)
    return if url.blank?

    data = selector2query(index, selectors, options, aggs_interval)

    response = make_request(url, data: data, method: :post)

    with_interval = aggs_interval.present? && aggs_interval[:interval].present?

    if !response.success?
      # Work around a bug with ES versions <= 8.5.0, where invalid date range conditions caused an error response from the server.
      # https://github.com/zammad/zammad/issues/5105, https://github.com/elastic/elasticsearch/issues/88131
      # This can probably be removed when the required minimum ES version is >= 8.5.0.
      if with_interval && response.code.to_i == 400 && response.body&.include?('illegal_argument_exception')
        return fake_empty_es_aggregation_response
      end

      raise humanized_error(
        verb:     'GET',
        url:      url,
        payload:  data,
        response: response,
      )
    end
    Rails.logger.debug { response.data.to_json }

    if !with_interval
      object_ids = response.data['hits']['hits'].pluck('_id')

      # in lower ES 6 versions, we get total count directly, in higher
      # versions we need to pick it from total has
      count = response.data['hits']['total']
      if response.data['hits']['total'].class != Integer
        count = response.data['hits']['total']['value']
      end
      return {
        count:      count,
        object_ids: object_ids,
      }
    end
    response.data
  end

  def self.selector2query(index, selector, options, aggs_interval)
    Selector::SearchIndex.new(selector: selector, options: options.merge(aggs_interval: aggs_interval), target_class: index.constantize).get
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

  def self.build_url(type: nil, action: nil, object_id: nil, with_pipeline: true, with_document_type: true, url_params: {})
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

    message = if response&.error&.match?('Connection refused') # rubocop:disable Zammad/DetectTranslatableString
                __("Elasticsearch is not reachable. It's possible that it's not running. Please check whether it is installed.")
              elsif url.end_with?('pipeline/zammad-attachment', 'pipeline=zammad-attachment') && response.code == 400
                __('The installed attachment plugin could not handle the request payload. Ensure that the correct attachment plugin is installed (ingest-attachment).')
              else
                __('Check the response and payload for detailed information:')
              end

    result = "#{prefix} #{message}#{suffix}"
    Rails.logger.error result.first(40_000)
    result
  end

  # add * on simple query like "somephrase23"
  def self.append_wildcard_to_simple_query(query)
    query = query.strip
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
@option options [Array<String>] :fulltext If no sorting is defined the current fallback is the sorting by updated_at. But for fulltext searches it makes more sense to search by _score as default. This parameter allows to change to the fallback to _score.

=end

  DEFAULT_QUERY_OPTIONS = {
    from:  0,
    limit: 10
  }.freeze

  def self.build_query(index, condition, options = {})
    options[:from] = options[:from].presence || options[:offset].presence
    options        = DEFAULT_QUERY_OPTIONS.merge(options.compact_blank.deep_symbolize_keys)

    data = {
      from:  options[:from],
      size:  options[:limit],
      sort:  search_by_index_sort(index: index, sort_by: options[:sort_by], order_by: options[:order_by], fulltext: options[:fulltext]),
      query: {
        bool: {
          must:     [],
          must_not: [],
        }
      }
    }

    if (extension = options[:query_extension])
      data[:query].deep_merge! extension.deep_dup
    end

    data[:query][:bool][:must].push condition

    if options[:ids].present?
      data[:query][:bool][:must].push({ ids: { values: options[:ids] } })
    end

    if options[:condition].present?
      selector_query = SearchIndexBackend.selector2query(index, options[:condition], {}, nil)
      data[:query][:bool][:must] += Array.wrap(selector_query[:query][:bool][:must])
      data[:query][:bool][:must_not] += Array.wrap(selector_query[:query][:bool][:must_not])
    end

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
      verify_ssl:        Setting.get('es_ssl_verify'),
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
    response = make_request(url, **args)

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
    result = {
      properties: {}
    }

    store_columns = %w[preferences data condition condition_selected condition_saved perform options view order match timeplan]

    # for elasticsearch 6.x and later
    string_type = 'text'
    string_raw  = { type: 'keyword', ignore_above: 5012 }
    boolean_raw = { type: 'boolean' }

    object.columns_hash.each do |key, value|
      if value.type == :string && value.limit && value.limit <= 5000 && store_columns.exclude?(key)
        result[:properties][key] = {
          type:   string_type,
          fields: {
            keyword: string_raw,
          }
        }
      elsif value.type == :integer
        result[:properties][key] = {
          type: 'integer',
        }
      elsif value.type == :datetime || value.type == :date # rubocop:disable Style/MultipleComparison
        result[:properties][key] = {
          type: 'date',
        }
      elsif value.type == :boolean
        result[:properties][key] = {
          type:   'boolean',
          fields: {
            keyword: boolean_raw,
          }
        }
      elsif value.type == :binary
        result[:properties][key] = {
          type: 'binary',
        }
      elsif value.type == :bigint
        result[:properties][key] = {
          type: 'long',
        }
      elsif value.type == :decimal
        result[:properties][key] = {
          type: 'float',
        }
      elsif value.type == :jsonb
        result[:properties][key] = {
          properties: {
            label: {
              type:   string_type,
              fields: {
                keyword: string_raw
              }
            },
            value: {
              type:   string_type,
              fields: {
                keyword: string_raw
              }
            }
          }
        }
      end
    end

    case object.name
    when 'Ticket'
      result[:properties][:article] = {
        type:              'nested',
        include_in_parent: true,
      }
    end

    result
  end

  # get es version
  def self.version
    @version ||= SearchIndexBackend.info&.dig('version', 'number')
  end

  def self.configured?
    Setting.get('es_url').present?
  end

  def self.model_indexable?(model_name)
    Models.indexable.any? { |m| m.name == model_name }
  end

  def self.default_model_settings
    {
      'index.mapping.total_fields.limit' => 2000,
    }
  end

  def self.model_settings(model)
    settings = Setting.get('es_model_settings')[model.name] || {}
    default_model_settings.merge(settings)
  end

  def self.all_settings
    Models.indexable.each_with_object({}).to_h { |m| [m.name, model_settings(m)] }
  end

  def self.set_setting(model_name, key, value)
    raise "It is not possible to configure settings for the non-indexable model '#{model_name}'." if !model_indexable?(model_name)
    raise __("The required parameter 'key' is missing.") if key.blank?
    raise __("The required parameter 'value' is missing.") if value.blank?

    config = Setting.get('es_model_settings')
    config[model_name] ||= {}
    config[model_name][key] = value

    Setting.set('es_model_settings', config)
  end

  def self.unset_setting(model_name, key)
    raise "It is not possible to configure settings for the non-indexable model '#{model_name}'." if !model_indexable?(model_name)
    raise __("The required parameter 'key' is missing.") if key.blank?

    config = Setting.get('es_model_settings')
    config[model_name] ||= {}
    config[model_name].delete(key)

    Setting.set('es_model_settings', config)
  end

  def self.create_index(models = Models.indexable)
    models.each do |local_object|
      SearchIndexBackend.index(
        action: 'create',
        name:   local_object.name,
        data:   {
          mappings: SearchIndexBackend.get_mapping_properties_object(local_object),
          settings: model_settings(local_object),
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
      pipeline = "zammad#{SecureRandom.uuid}"
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
          description: __('Extract zammad-attachment information from arrays'),
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

  # Simulate an empty response from ES.
  def self.fake_empty_es_aggregation_response
    {
      'hits'         => { 'total' => { 'value' => 0, 'relation' => 'eq' }, 'max_score' => nil, 'hits' => [] },
      'aggregations' => { 'time_buckets' => { 'buckets' => [] } }
    }
  end
end
