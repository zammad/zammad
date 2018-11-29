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
  # Parse the incoming response document via a SAX parser instead of the
  # traditional DOM parser. In early benchmarks this was performing about
  # 132% faster than the DOM-based parser for large documents.
  class EwsSaxDocument < Nokogiri::XML::SAX::Document
    include Viewpoint::EWS
    include Viewpoint::StringUtils

    attr_reader :struct

    def initialize
      @struct = {}
      @elems  = []
    end

    def characters(string)
      # FIXME: Move white space removal to somewhere else.
      # This function can be called multiple times. In this case newlines in Text Bodies get stripped.
      # See: https://github.com/zenchild/Viewpoint/issues/90
      #string.strip!
      return if string.empty?
      if @elems.last[:text]
        @elems.last[:text] += string
      else
        @elems.last[:text] = string
      end
    end

    def start_element_namespace(name, attributes = [], prefix = nil, uri = nil, ns = [])
      name = ruby_case(name).to_sym
      elem = {}
      unless attributes.empty?
        elem[:attribs] = attributes.collect{|a|
          { ruby_case(a.localname).to_sym => a.value}
        }.inject(&:merge)
      end
      @elems << elem
    end

    def end_element_namespace name, prefix=nil, uri=nil
      name = ruby_case(name).to_sym
      elem = @elems.pop
      if @elems.empty?
        @struct[name] = elem
      else
        @elems.last[:elems] = [] unless @elems.last[:elems].is_a?(Array)
        @elems.last[:elems] << {name => elem}
      end
    end

  end
end
