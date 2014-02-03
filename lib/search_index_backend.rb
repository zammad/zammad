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

    puts "# curl -X PUT \"#{url}\" -d '#{data[:data].to_json}'"

    conn     = connection( url )
    response = conn.put do |req|
      req.url url
      req.headers['Content-Type'] = 'application/json'
      req.body = data[:data].to_json
    end
    puts "# #{response.status.to_s}"
    return true if response.success?
    data = JSON.parse( response.body )
    raise data.inspect
  end

=begin

add new object to search index

  SearchIndexBackend.add( 'Ticket', some_data_object )

=end

  def self.add(type, data)

    url = build_url( type, data['id'] )
    return if !url

    puts "# curl -X POST \"#{url}\" -d '#{data.to_json}'"

    conn     = connection( url )
    response = conn.post do |req|
      req.url url
      req.headers['Content-Type'] = 'application/json'
      req.body = data.to_json
    end
    puts "# #{response.status.to_s}"
    return true if response.success?
    data = JSON.parse( response.body )
    raise data.inspect
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

    conn     = connection( url )
    response = conn.delete( url )
    puts "# #{response.status.to_s}"
    return false if !response.success?
    data = JSON.parse( response.body )
#    raise data.inspect
    return { :data => data, :response => response }
  end

=begin

return search result

  result = SearchIndexBackend.search( 'search query', limit, 'User' )

=end

  def self.search( query, limit = 10, index = nil, query_extention = {} )
    return [] if !query

    url = build_url()
    return if !url
    if index 
      url += "/#{index}/_search"
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

    puts "# curl -X POST \"#{url}\" -d '#{data.to_json}'"

    conn     = connection( url )
    response = conn.get do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = data.to_json
    end
    puts "# #{response.status.to_s}"
    data = JSON.parse( response.body )
    if !response.success?
      return []
#      raise data.inspect
    end

    ids = []
    return ids if !data
    return ids if !data['hits']
    return ids if !data['hits']['hits']
    data['hits']['hits'].each { |item|
      puts "... #{item['_type'].to_s} #{item['_id'].to_s}"
      ids.push item['_id']
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

  def self.connection( url )
    conn = Faraday.new( :url => url )
    user = Setting.get('es_user')
    pw   = Setting.get('es_password')
    if user && !user.empty? && pw && !pw.empty?
      conn.basic_auth( user, pw )
    end
    conn
  end

end