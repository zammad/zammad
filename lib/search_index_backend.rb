# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class SearchIndexBackend
  @@index = "zammad_#{Rails.env}"
  @@url   = 'http://127.0.0.1:9000'
  @@user  = 'elasticsearch'
  @@pw    = 'zammad'

=begin

add new object to search index

  SearchIndexBackend.add( 'Ticket', some_data_object )

=end

  def self.add(type, data)

    url = "#{@@url}/#{@@index}/#{type}/#{data[:id]}"

    puts "# curl -X POST \"#{url}\" -d '#{data.to_json}'"

    conn = Faraday.new( :url => url )
    if @@user && @@pw
      conn.basic_auth( @@user, @@pw )
    end

    response = conn.post do |req|
      req.url url
      req.headers['Content-Type'] = 'application/json'
      req.body = data.to_json
    end
#    puts response.body.to_s
    puts "# #{response.status.to_s}"
    return true if response.success?
    data = JSON.parse( response.body )
    return { :data => data, :response => response }
  end

=begin

remove whole data from index

  SearchIndexBackend.remove( 'Ticket', 123 )

  SearchIndexBackend.remove( 'Ticket' )

=end

  def self.remove( type, o_id = nil )
    if o_id
      url = "#{@@url}/#{@@index}/#{type}/#{o_id}"
    else
      url = "#{@@url}/#{@@index}/#{type}"
    end

    puts "# curl -X DELETE \"#{url}\""

    conn = Faraday.new( :url => url )
    if @@user && @@pw
      conn.basic_auth( @@user, @@pw )
    end
    response = conn.delete url
#    puts response.body.to_s
    puts "# #{response.status.to_s}"
    return true if response.success?
    data = JSON.parse( response.body )
    return { :data => data, :response => response }
  end

=begin

return all activity entries of an user

  result = SearchIndexBackend.search( user )

=end

  def self.search(user,limit)
  end

end