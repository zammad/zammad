# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

module User::SearchIndex

=begin

get data to store in search index

  user = User.find(123)
  result = user.search_index_data

returns

  result = true # false

=end

  def search_index_data
    data = []
    data.push "#{ self['firstname'] } #{ self['lastname'] }"
    ['login', 'firstname', 'lastname', 'phone', 'email', 'city', 'country', 'note'].each { |key|
      data.push self[key] if self[key]
    }
    data
  end
end