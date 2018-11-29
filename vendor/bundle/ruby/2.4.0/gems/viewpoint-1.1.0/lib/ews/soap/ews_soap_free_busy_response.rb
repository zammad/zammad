=begin
  This file is a cotribution to Viewpoint; the Ruby library for Microsoft Exchange Web Services.

  Copyright © 2013 Mark McCahill <mark.mccahill@duke.edu>

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
=end

module Viewpoint::EWS::SOAP

  class EwsSoapFreeBusyResponse  < EwsSoapResponse

    def initialize(sax_hash)
      @resp = sax_hash
      simplify!
    end

    def envelope
      @resp[:envelope][:elems]
    end

    def header
      envelope[0][:header][:elems]
    end

    def body
      envelope[1][:body][:elems]
    end

    def get_user_availability_response
      body.first[:get_user_availability_response][:elems].first[:free_busy_response_array][:elems].first[:free_busy_response][:elems]
    end

    def response
      body
    end

    def calendar_event_array
      result = find_in_hash_list(get_user_availability_response[1][:free_busy_view][:elems], :calendar_event_array)
      result ? result[:elems] : []
    end

    def working_hours
      get_user_availability_response[1][:free_busy_view][:elems][2][:working_hours][:elems]
    end

    def response_message
      find_in_hash_list(get_user_availability_response, :response_message)
    end

    def response_class
      response_message[:attribs][:response_class]
    end
    alias :status :response_class

    def response_code
      result = find_in_hash_list(response_message[:elems], :response_code)
      result ? result[:text] : nil
    end
    alias :code :response_code

    def response_message_text
      guard_hash response_message[:elems], [:message_text, :text]
    end
    alias :message :response_message_text

    def response_key
      response_message[:elems]
    end

    def success?
      response_class == "Success"
    end

    private

    def simplify!
#     key = response_key
#     body[0][key] = body[0][key][:elems].inject(:merge)
#     response_message[:elems] = response_message[:elems].inject(:merge)
    end

    # If the keys don't exist in the Hash return nil
    # @param[Hash] hsh
    # @param[Array<Symbol,String>] keys keys to follow in the array
    # @return [Object, nil]
    def guard_hash(hsh, keys)
      key = keys.shift
      return nil unless hsh.is_a?(Hash) && hsh.has_key?(key)

      if keys.empty?
        hsh[key]
      else
        guard_hash hsh[key], keys
      end
    end

    # Find the first element in a list of hashes or return nil
    # Example:
    #     find_in_hash_list([{:foo => :bar}, {:bar => :baz}], :foo)
    #     => :bar
    def find_in_hash_list(collection, key)
      result = collection.find { |hsh| hsh.keys.include?(key) }
      result ? result[key] : nil
    end

  end # EwsSoapFreeBusyResponse

end # Viewpoint::EWS::SOAP
