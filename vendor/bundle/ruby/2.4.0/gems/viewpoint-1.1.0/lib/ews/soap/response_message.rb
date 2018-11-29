=begin
  This file is part of Viewpoint; the Ruby library for Microsoft Exchange Web Services.

  Copyright © 2011 Dan Wanek <dan.wanek@gmail.com>

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
  class ResponseMessage

    attr_reader :message, :type

    def initialize(message)
      @type    = message.keys.first
      @message = message[@type]
    end

    def response_class
      message[:attribs][:response_class]
    end
    alias :status :response_class

    def success?
      response_class == 'Success'
    end

    def message_text
      safe_hash_access message, [:elems, :message_text, :text]
    end

    def response_code
      safe_hash_access message, [:elems, :response_code, :text]
    end
    alias :code :response_code

    def message_xml
      safe_hash_access message, [:elems, :message_xml, :text]
    end

    def items
      safe_hash_access(message, [:elems, :items, :elems]) || []
    end


    private


    def safe_hash_access(hsh, keys)
      key = keys.shift
      return nil unless hsh.is_a?(Hash) && hsh.has_key?(key)

      if keys.empty?
        hsh[key]
      else
        safe_hash_access hsh[key], keys
      end
    end

  end
end # Viewpoint::EWS::SOAP

require_relative './responses/create_item_response_message'
require_relative './responses/create_attachment_response_message'
require_relative './responses/find_item_response_message'
require_relative './responses/subscribe_response_message'
require_relative './responses/get_events_response_message'
require_relative './responses/send_notification_response_message'
require_relative './responses/sync_folder_items_response_message'
require_relative './responses/sync_folder_hierarchy_response_message'
