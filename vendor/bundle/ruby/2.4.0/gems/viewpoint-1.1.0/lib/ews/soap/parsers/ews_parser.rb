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
  class EwsParser
    include Viewpoint::EWS

    # @param [String] soap_resp
    def initialize(soap_resp)
      @soap_resp  = soap_resp
      @sax_doc    = EwsSaxDocument.new
    end

    def parse(opts = {})
      opts[:response_class] ||= EwsSoapResponse
      @soap_resp.gsub!(/&#x([0-8bcef]|1[0-9a-f]);/i, '')
      sax_parser.parse(@soap_resp)
      opts[:response_class].new @sax_doc.struct
    end

    private

    def sax_parser
      @parser ||= Nokogiri::XML::SAX::Parser.new(@sax_doc)
    end

  end # EwsParser
end # Viewpoint
