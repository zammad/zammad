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
    fail response.inspect
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
    fail response.inspect
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
    if index
      if index.class == Array
        url += "/#{index.join(',')}/_search"
      else
        url += "/#{index}/_search"
      end
    else
      url += '/_search'
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

return aggregation result

  result = SearchIndexBackend.aggs(
    {
      title: 'test',
      state_id: 4,
    },
    ['2014-10-19', '2015-10-19', 'created_at', 'month'],
    ['Ticket'],
  )

  # year, quarter, month, week, day, hour, minute, second

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

  def self.aggs(query, range, index = nil)

    url = build_url()
    return if !url
    if index
      if index.class == Array
        url += "/#{index.join(',')}/_search"
      else
        url += "/#{index}/_search"
      end
    else
      url += '/_search'
    end

    and_data = []
    if query && !query.empty?
      bool = {
        bool: {
          must: {
            term: query,
          },
        },
      }
      and_data.push bool
    end
    range_data = {}
    range_data[range[2]] = {
      from: range[0],
      to: range[1],
    }
    range_data_and = {
      range: range_data,
    }
    and_data.push range_data_and

    data = {
      query: {
        filtered: {
          filter: {
            and: and_data,
          }
        }
      },
      size: 0,
      aggs: {
        time_buckets: {
          date_histogram: {
            field: range[2],
            interval: range[3],
          }
        }
      }
    }

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
    Rails.logger.debug response.data.to_json
    response.data
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
    if type
      if o_id
        url = "#{url}/#{index}/#{type}/#{o_id}"
      else
        url = "#{url}/#{index}/#{type}"
      end
    else
      url = "#{url}/#{index}"
    end
    url
  end

end
