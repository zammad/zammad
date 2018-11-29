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

  # This is a speciality response class to handle the idiosynracies of
  # Availability responses.
  # @attr_reader [String] :message The text from the EWS element <m:ResponseCode>
  class EwsSoapAvailabilityResponse < EwsSoapResponse

    def response_messages
      nil
    end

    def response
      body[0][response_key]
    end

    def response_message
      key = response.keys.first
      response[key]
    end

    def response_code
      response_message[:elems][:response_code][:text]
    end
    alias :code :response_code

    def response_key
      key = body[0].keys.first
    end

    private

    def simplify!
      key = response_key
      body[0][key] = body[0][key][:elems].inject(:merge)
      response_message[:elems] = response_message[:elems].inject(:merge)
    end

  end # EwsSoapAvailabilityResponse

end # Viewpoint::EWS::SOAP
