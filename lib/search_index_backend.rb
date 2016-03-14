# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class SearchIndexBackend

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
                'attachments' => { :type => 'attachment' }
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

    url = build_url( data[:name] )
    return if !url

    if data[:action] && data[:action] == 'delete'
      return SearchIndexBackend.remove( data[:name] )
    end

    Rails.logger.info "# curl -X PUT \"#{url}\" \\"
    Rails.logger.debug "-d '#{data[:data].to_json}'"

    response = UserAgent.put(
      url,
      data[:data],
      {
        json: true,
        open_timeout: 5,
        read_timeout: 20,
        user: Setting.get('es_user'),
        password: Setting.get('es_password'),
      }
    )
    Rails.logger.info "# #{response.code}"
    return true if response.success?
    raise response.inspect
  end

=begin

add new object to search index

  SearchIndexBackend.add( 'Ticket', some_data_object )

=end

  def self.add(type, data)

    url = build_url( type, data['id'] )
    return if !url

    Rails.logger.info "# curl -X POST \"#{url}\" \\"
    Rails.logger.debug "-d '#{data.to_json}'"

    response = UserAgent.post(
      url,
      data,
      {
        json: true,
        open_timeout: 5,
        read_timeout: 20,
        user: Setting.get('es_user'),
        password: Setting.get('es_password'),
      }
    )
    Rails.logger.info "# #{response.code}"
    return true if response.success?
    raise response.inspect
  end

=begin

remove whole data from index

  SearchIndexBackend.remove( 'Ticket', 123 )

  SearchIndexBackend.remove( 'Ticket' )

=end

  def self.remove( type, o_id = nil )
    url = build_url( type, o_id )
    return if !url

    Rails.logger.info "# curl -X DELETE \"#{url}\""

    response = UserAgent.delete(
      url,
      {
        open_timeout: 5,
        read_timeout: 14,
        user: Setting.get('es_user'),
        password: Setting.get('es_password'),
      }
    )
    Rails.logger.info "# #{response.code}"
    return true if response.success?
    #Rails.logger.info "NOTICE: can't drop index: " + response.inspect
    false
  end

=begin

return search result

  result = SearchIndexBackend.search( 'search query', limit, ['User', 'Organization'] )

  result = SearchIndexBackend.search( 'search query', limit, 'User' )

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

  def self.search( query, limit = 10, index = nil, query_extention = {} )
    return [] if !query

    url = build_url()
    return if !url
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
    data['from'] = 0
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
    if !data['query']['bool']
      data['query']['bool'] = {}
    end
    if !data['query']['bool']['must']
      data['query']['bool']['must'] = []
    end

    # add * on simple query search
    if query && query =~ /^\w+$/
      query += '*'
    end

    # real search condition
    condition = {
      'query_string' => {
        'query' => query
      }
    }
    data['query']['bool']['must'].push condition

    Rails.logger.info "# curl -X POST \"#{url}\" \\"
    Rails.logger.debug " -d'#{data.to_json}'"

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
      Rails.logger.error "ERROR: #{response.inspect}"
      return []
    end
    data = response.data

    ids = []
    return ids if !data
    return ids if !data['hits']
    return ids if !data['hits']['hits']
    data['hits']['hits'].each { |item|
      Rails.logger.info "... #{item['_type']} #{item['_id']}"
      data = {
        id: item['_id'],
        type: item['_type'],
      }
      ids.push data
    }
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

    url = build_url()
    return if !url
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
    Rails.logger.debug " -d'#{data.to_json}'"

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
      raise "ERROR: #{response.inspect}"
    end
    Rails.logger.debug response.data.to_json

    if !aggs_interval || !aggs_interval[:interval]
      ticket_ids = []
      response.data['hits']['hits'].each {|item|
        ticket_ids.push item['_id']
      }
      return {
        count: response.data['hits']['total'],
        ticket_ids: ticket_ids,
      }
    end
    response.data
  end

  def self.selector2query(selector, _current_user, aggs_interval, limit)
    filter_must = []
    filter_must_not = []
    query_must = []
    query_must_not = []
    if selector && !selector.empty?
      selector.each {|key, data|
        key_tmp = key.sub(/^.+?\./, '')
        t = {}
        if data['value'].class == Array
          t[:terms] = {}
          t[:terms][key_tmp] = data['value']
        else
          t[:term] = {}
          t[:term][key_tmp] = data['value']
        end
        if data['operator'] == 'is'
          filter_must.push t
        elsif data['operator'] == 'is not'
          filter_must_not.push t
        elsif data['operator'] == 'contains'
          query_must.push t
        elsif data['operator'] == 'contains not'
          query_must_not.push t
        else
          raise "unknown operator '#{data['operator']}'"
        end
      }
    end
    data = {
      query: {},
      size: limit,
    }

    # add aggs to filter
    if aggs_interval
      if aggs_interval[:interval]
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
      filter_must.push r
    end

    if !query_must.empty? || !query_must_not.empty?
      if !data[:query][:filtered]
        data[:query][:filtered] = {}
      end
      if !data[:query][:filtered][:query]
        data[:query][:filtered][:query] = {}
      end
      if !data[:query][:filtered][:query][:bool]
        data[:query][:filtered][:query][:bool] = {}
      end
    end
    if !query_must.empty?
      data[:query][:filtered][:query][:bool][:must] = query_must
    end
    if !query_must_not.empty?
      data[:query][:filtered][:query][:bool][:must_not] = query_must_not
    end

    if !filter_must.empty? || !filter_must.empty?
      if !data[:query][:filtered]
        data[:query][:filtered] = {}
      end
      if !data[:query][:filtered][:filter]
        data[:query][:filtered][:filter] = {}
      end
      if !data[:query][:filtered][:filter][:bool]
        data[:query][:filtered][:filter][:bool] = {}
      end
    end
    if !filter_must.empty?
      data[:query][:filtered][:filter][:bool][:must] = filter_must
    end
    if !filter_must_not.empty?
      data[:query][:filtered][:filter][:bool][:must_not] = filter_must_not
    end

    # add sort
    if aggs_interval && aggs_interval[:field] && !aggs_interval[:interval]
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
    return if !Setting.get('es_url')
    return if Setting.get('es_url').empty?
    true
  end

  def self.build_url( type = nil, o_id = nil )
    return if !SearchIndexBackend.enabled?
    index = Setting.get('es_index').to_s + "_#{Rails.env}"
    url   = Setting.get('es_url')
    url = if type
            if o_id
              "#{url}/#{index}/#{type}/#{o_id}"
            else
              "#{url}/#{index}/#{type}"
            end
          else
            "#{url}/#{index}"
          end
    url
  end

end
