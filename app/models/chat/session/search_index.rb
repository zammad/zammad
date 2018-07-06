# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module Chat::Session::SearchIndex
  extend ActiveSupport::Concern

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

=begin

lookup name of ref. objects

  chat_session = Chat::Session.find(123)
  result = chat_session.search_index_attribute_lookup

returns

  attributes # object with lookup data

=end

    def search_index_attribute_lookup
      attributes = super
      return if !attributes

      attributes[:tags] = tag_list

      messages = Chat::Message.where(chat_session_id: id)
      attributes['messages'] = []
      messages.each do |message|

        # lookup attributes of ref. objects (normally name and note)
        message_attributes = message.search_index_attribute_lookup

        attributes['messages'].push message_attributes
      end

      attributes
    end
  end

end
