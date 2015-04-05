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
            :articles_all => {
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

    puts "# curl -X PUT \"#{url}\" \\"
    #puts "-d '#{data[:data].to_json}'"

    response = UserAgent.put(
      url,
      data[:data],
      {
        :json         => true,
        :open_timeout => 5,
        :read_timeout => 20,
        :user         => Setting.get('es_user'),
        :password     => Setting.get('es_password'),
      }
    )
    puts "# #{response.code.to_s}"
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

    puts "# curl -X POST \"#{url}\" \\"
    #puts "-d '#{data.to_json}'"

    response = UserAgent.post(
      url,
      data,
      {
        :json         => true,
        :open_timeout => 5,
        :read_timeout => 20,
        :user         => Setting.get('es_user'),
        :password     => Setting.get('es_password'),
      }
    )
    puts "# #{response.code.to_s}"
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

    puts "# curl -X DELETE \"#{url}\""

    response = UserAgent.delete(
      url,
      {
        :open_timeout => 5,
        :read_timeout => 14,
        :user         => Setting.get('es_user'),
        :password     => Setting.get('es_password'),
      }
    )
    #puts "# #{response.code.to_s}"
    return true if response.success?
    puts "NOTICE: can't drop index: " + response.inspect
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
    data['size'] = 10
    data['sort'] =
    [
      {
        :updated_at => {
          :order => 'desc'
        }
      },
      "_score"
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

    puts "# curl -X POST \"#{url}\" \\"
    #puts " -d'#{data.to_json}'"

    response = UserAgent.get(
      url,
      data,
      {
        :json         => true,
        :open_timeout => 5,
        :read_timeout => 14,
        :user         => Setting.get('es_user'),
        :password     => Setting.get('es_password'),
      }
    )

    puts "# #{response.code.to_s}"
    if !response.success?
      return []
#      raise data.inspect
    end
    data = response.data

    ids = []
    return ids if !data
    return ids if !data['hits']
    return ids if !data['hits']['hits']
    data['hits']['hits'].each { |item|
      puts "... #{item['_type'].to_s} #{item['_id'].to_s}"
      data = {
        :id   => item['_id'],
        :type => item['_type'],
      }
      ids.push data
    }
    ids
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


  private

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