# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class User
  module SearchIndex

=begin

get data to store in search index

  user = User.find(123)
  result = user.search_index_data

returns

  result = true # false

=end

    def search_index_data
      attributes = { 'fullname' => "#{self['firstname']} #{self['lastname']}" }
      %w(login firstname lastname phone email address city country note created_at).each { |key|
        if self[key] && (!self.respond_to?('empty?') || !self[key].empty?)
          attributes[key] = self[key]
        end
      }
      return if attributes.empty?
      attributes
    end
  end
end
