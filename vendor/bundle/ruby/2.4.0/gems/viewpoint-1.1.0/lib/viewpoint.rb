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

require 'kconv' if(RUBY_VERSION.start_with? '1.9') # bug in rubyntlm with ruby 1.9.x
require 'date'
require 'base64'
require 'nokogiri'
require 'ostruct'
require 'logging'

# String utilities
require 'viewpoint/string_utils'

# Load the logging setup
require 'viewpoint/logging'

# Load the Exception classes
require 'ews/exceptions/exceptions'

# Load the backend SOAP / EWS infrastructure.
require 'ews/soap'
require 'ews/soap/response_message'
require 'ews/soap/ews_response'
require 'ews/soap/ews_soap_response'
require 'ews/soap/ews_soap_availability_response'
require 'ews/soap/ews_soap_free_busy_response'
require 'ews/soap/ews_soap_room_response'
require 'ews/soap/ews_soap_roomlist_response'
require 'ews/soap/builders/ews_builder'
require 'ews/soap/parsers/ews_parser'
require 'ews/soap/parsers/ews_sax_document'
# Mix-ins for the ExchangeWebService
require 'ews/soap/exchange_data_services'
require 'ews/soap/exchange_notification'
require 'ews/soap/exchange_synchronization'
require 'ews/soap/exchange_availability'
require 'ews/soap/exchange_user_configuration'
require 'ews/soap/exchange_time_zones'
require 'ews/soap/exchange_web_service'

require 'ews/errors'
require 'ews/connection_helper'
require 'ews/connection'

require 'ews/impersonation'

# Base Types
require 'ews/types'
require 'ews/types/item_field_uri_map'
require 'ews/types/generic_folder'
require 'ews/types/item'
# Folders
require 'ews/types/folder'
require 'ews/types/calendar_folder'
require 'ews/types/contacts_folder'
require 'ews/types/tasks_folder'
require 'ews/types/search_folder'
# Items
require 'ews/types/message'
require 'ews/types/calendar_item'
require 'ews/types/contact'
require 'ews/types/distribution_list'
require 'ews/types/meeting_message'
require 'ews/types/meeting_request'
require 'ews/types/meeting_response'
require 'ews/types/meeting_cancellation'
require 'ews/types/task'
require 'ews/types/attachment'
require 'ews/types/file_attachment'
require 'ews/types/item_attachment'
require 'ews/types/mailbox_user'
require 'ews/types/out_of_office'
require 'ews/types/export_items_response_message'
require 'ews/types/post_item'

# Events
require 'ews/types/event'
require 'ews/types/copied_event'
require 'ews/types/created_event'
require 'ews/types/deleted_event'
require 'ews/types/free_busy_changed_event'
require 'ews/types/modified_event'
require 'ews/types/moved_event'
require 'ews/types/new_mail_event'
require 'ews/types/status_event'

# Template Objects
require 'ews/templates/message'
require 'ews/templates/forward_item'
require 'ews/templates/reply_to_item'
require 'ews/templates/calendar_item'
require 'ews/templates/task'

# The proxy between the models and the web service
require 'ews/ews_client'
