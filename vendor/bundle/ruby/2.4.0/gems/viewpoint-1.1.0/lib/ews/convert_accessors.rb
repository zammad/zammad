=begin
  This file is part of Viewpoint; the Ruby library for Microsoft Exchange Web Services.

  Copyright © 2013 Dan Wanek <dan.wanek@gmail.com>

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
module Viewpoint::EWS::ConvertAccessors
  include Viewpoint::EWS

  # This is a class method that converts identifiers between formats.
  # @param [String] id The id to be converted
  # @param [Hash] opts Misc options to control request
  # @option opts [Symbol] :format :ews_legacy_id/:ews_id/:entry_id/:hex_entry_id/:store_id/:owa_id
  # @option opts [Symbol] :destination_format :ews_legacy_id/:ews_id/:entry_id/:hex_entry_id/:store_id/:owa_id
  # @option opts [String] :mailbox Mailbox, if required
  # @return [EwsResponse] Returns an EwsResponse containing the convert response message

  def convert_id(id, opts = {})
    args = convert_id_args(id, opts.clone)
    obj = OpenStruct.new(opts: args)
    yield obj if block_given?
    resp = ews.convert_id(args)
    convert_id_parser(resp)
  end

  private

  def convert_id_args(id, opts)
    { id: id }.merge opts
  end

  def convert_id_parser(resp)
    rm = resp.response_messages[0]

    if(rm && rm.status == 'Success')
      # @todo create custom response class
      rm
    else
      code = rm.respond_to?(:code) ? rm.code : "Unknown"
      text = rm.respond_to?(:message_text) ? rm.message_text : "Unknown"
      raise EwsError, "Could not convert id. #{rm.code}: #{rm.message_text}"
    end
  end

end # Viewpoint::EWS::ItemAccessors
