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
        json: true,
        open_timeout: 8,
        read_timeout: 12,
        user: Setting.get('es_user'),
        password: Setting.get('es_password'),
      }
    )
    Rails.logger.info "# #{response.code}"
    if response.success?
      installed_version = response.data.dig('version', 'number')
      raise "Unable to get elasticsearch version from response: #{response.inspect}" if installed_version.blank?
      version_supported = Gem::Version.new(installed_version) < Gem::Version.new('5.7')
      raise "Version #{installed_version} of configured elasticsearch is not supported" if !version_supported
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
              json: true,
              open_timeout: 8,
              read_timeout: 12,
              user: Setting.get('es_user'),
              password: Setting.get('es_password'),
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
            json: true,
            open_timeout: 8,
            read_timeout: 12,
            user: Setting.get('es_user'),
            password: Setting.get('es_password'),
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
    :name   => 'Ticket',    # optional
  )

  SearchIndexBackend.index(
    :action => 'delete',  # create/update/delete
  )
=end

  def self.index(data)

    url = build_url(data[:name])
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
        json: true,
        open_timeout: 8,
        read_timeout: 30,
        user: Setting.get('es_user'),
        password: Setting.get('es_password'),
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
        json: true,
        open_timeout: 8,
        read_timeout: 16,
        user: Setting.get('es_user'),
        password: Setting.get('es_password'),
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
    url = build_url(type, o_id)
    return if url.blank?

    Rails.logger.info "# curl -X DELETE \"#{url}\""

    response = UserAgent.delete(
      url,
      {
        open_timeout: 8,
        read_timeout: 16,
        user: Setting.get('es_user'),
        password: Setting.get('es_password'),
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

return search result

  result = SearchIndexBackend.search('search query', limit, ['User', 'Organization'])

  result = SearchIndexBackend.search('search query', limit, 'User')

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

  def self.search(query, limit = 10, index = nil, query_extention = {}, from = 0)
    return [] if query.blank?
    if index.class == Array
      ids = []
      index.each do |local_index|
        local_ids = search_by_index(query, limit, local_index, query_extention, from)
        ids = ids.concat(local_ids)
      end
      return ids
    end
    search_by_index(query, limit, index, query_extention, from)
  end

  def self.search_by_index(query, limit = 10, index = nil, query_extention = {}, from)
    return [] if query.blank?

    url = build_url
    return if url.blank?
    url += if index
             if index.class == Array
               "/#{index.join(',')}/_search"
             else
               "/#{index}/_search"
             end
           else
             '/_search'
           end
    data = {}
    data['from'] = from
    data['size'] = limit
    data['sort'] =
      [
        {
          updated_at: {
            order: 'desc'
          }
        },
        '_score'
      ]

    data['query'] = query_extention || {}
    data['query']['bool'] ||= {}
    data['query']['bool']['must'] ||= []

    # real search condition
    condition = {
      'query_string' => {
        'query' => append_wildcard_to_simple_query(query),
        'default_operator' => 'AND',
      }
    }
    data['query']['bool']['must'].push condition

    Rails.logger.info "# curl -X POST \"#{url}\" \\"
    Rails.logger.debug { " -d'#{data.to_json}'" }

    response = UserAgent.get(
      url,
      data,
      {
        json: true,
        open_timeout: 5,
        read_timeout: 14,
        user: Setting.get('es_user'),
        password: Setting.get('es_password'),
      }
    )

    Rails.logger.info "# #{response.code}"
    if !response.success?
      Rails.logger.error humanized_error(
        verb:     'GET',
        url:      url,
        payload:  data,
        response: response,
      )
      return []
    end
    data = response.data

    ids = []
    return ids if !data
    return ids if !data['hits']
    return ids if !data['hits']['hits']
    data['hits']['hits'].each do |item|
      Rails.logger.info "... #{item['_type']} #{item['_id']}"
      data = {
        id: item['_id'],
        type: item['_type'],
      }
      ids.push data
    end
    ids
  end

=begin

get count of tickets and tickets which match on selector

  aggs_interval = {
    from: '2015-01-01',
    to: '2015-12-31',
    interval: 'month', # year, quarter, month, week, day, hour, minute, second
    field: 'created_at',
  }

  result = SearchIndexBackend.selectors(index, params[:condition], limit, current_user, aggs_interval)

  # for aggregations
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

  def self.selectors(index = nil, selectors = nil, limit = 10, current_user = nil, aggs_interval = nil)
    raise 'no selectors given' if !selectors

    url = build_url
    return if url.blank?
    url += if index
             if index.class == Array
               "/#{index.join(',')}/_search"
             else
               "/#{index}/_search"
             end
           else
             '/_search'
           end

    data = selector2query(selectors, current_user, aggs_interval, limit)

    Rails.logger.info "# curl -X POST \"#{url}\" \\"
    Rails.logger.debug { " -d'#{data.to_json}'" }

    response = UserAgent.get(
      url,
      data,
      {
        json: true,
        open_timeout: 5,
        read_timeout: 14,
        user: Setting.get('es_user'),
        password: Setting.get('es_password'),
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
        count: response.data['hits']['total'],
        ticket_ids: ticket_ids,
      }
    end
    response.data
  end

  def self.selector2query(selector, _current_user, aggs_interval, limit)
    query_must = []
    query_must_not = []
    relative_map = {
      day: 'd',
      year: 'y',
      month: 'M',
      hour: 'h',
      minute: 'm',
    }
    if selector.present?
      selector.each do |key, data|
        key_tmp = key.sub(/^.+?\./, '')
        t = {}

        # is/is not/contains/contains not
        if data['operator'] == 'is' || data['operator'] == 'is not' || data['operator'] == 'contains' || data['operator'] == 'contains not'
          if data['value'].class == Array
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
            t[:range][key_tmp][:lt] = (data['value']).to_s
          else
            t[:range][key_tmp][:gt] = (data['value']).to_s
          end
          query_must.push t
        else
          raise "unknown operator '#{data['operator']}' for #{key}"
        end
      end
    end
    data = {
      query: {},
      size: limit,
    }

    # add aggs to filter
    if aggs_interval.present?
      if aggs_interval[:interval].present?
        data[:size] = 0
        data[:aggs] = {
          time_buckets: {
            date_histogram: {
              field: aggs_interval[:field],
              interval: aggs_interval[:interval],
            }
          }
        }
      end
      r = {}
      r[:range] = {}
      r[:range][aggs_interval[:field]] = {
        from: aggs_interval[:from],
        to: aggs_interval[:to],
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

  def self.build_url(type = nil, o_id = nil)
    return if !SearchIndexBackend.enabled?
    index = "#{Setting.get('es_index')}_#{Rails.env}"
    url   = Setting.get('es_url')
    url = if type
            url_pipline = Setting.get('es_pipeline')
            if url_pipline.present?
              url_pipline = "?pipeline=#{url_pipline}"
            end
            if o_id
              "#{url}/#{index}/#{type}/#{o_id}#{url_pipline}"
            else
              "#{url}/#{index}/#{type}#{url_pipline}"
            end
          else
            "#{url}/#{index}"
          end
    url
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

  # add * on simple query like "somephrase23" or "attribute: somephrase23"
  def self.append_wildcard_to_simple_query(query)
    query.strip!
    query += '*' if query.match?(/^([[:alnum:]._]+|[[:alnum:]]+\:\s*[[:alnum:]._]+)$/)
    query
  end
end
