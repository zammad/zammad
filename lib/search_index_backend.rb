# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class SearchIndexBackend

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
    url = build_url( type, o_id )
    return if !url

    puts "# curl -X DELETE \"#{url}\""

    conn     = connection( url )
    response = conn.delete( url )
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

  private

  def self.build_url( type, o_id = nil )
    index = Setting.get('es_index').to_s + "_#{Rails.env}"
    url   = Setting.get('es_url')
    return if !url
    if o_id
      url = "#{url}/#{index}/#{type}/#{o_id}"
    else
      url = "#{url}/#{index}/#{type}"
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