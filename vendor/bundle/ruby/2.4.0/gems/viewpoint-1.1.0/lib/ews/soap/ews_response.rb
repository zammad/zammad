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

  # A Generic Class for SOAP returns.
  class EwsResponse
    include Viewpoint::StringUtils

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

    def response
      body[0]
    end

    def response_messages
      return @response_messages if @response_messages

      @response_messages = []
      response_type = response.keys.first
      response[response_type][:elems][0][:response_messages][:elems].each do |rm|
        response_message_type = rm.keys[0]
        rm_klass = class_by_name(response_message_type)
        @response_messages << rm_klass.new(rm)
      end
      @response_messages
    end


    private


    def simplify!
      response_type = response.keys.first
      response[response_type][:elems][0][:response_messages][:elems].each do |rm|
        key = rm.keys.first
        rm[key][:elems] = rm[key][:elems].inject(&:merge)
      end
    end

    def class_by_name(cname)
      begin
        if(cname.instance_of? Symbol)
          cname = camel_case(cname)
        end
        Viewpoint::EWS::SOAP.const_get(cname)
      rescue NameError => e
        ResponseMessage
      end
    end

  end # EwsSoapResponse

end # Viewpoint::EWS::SOAP
