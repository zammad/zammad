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

  class CreateAttachmentResponseMessage < ResponseMessage
    include Viewpoint::StringUtils

    def attachments
      return @attachments if @attachments

      a = safe_hash_access message, [:elems, :attachments, :elems]
      @attachments = a.nil? ? nil : parse_attachments(a)
    end


    private


    def parse_attachments(att)
      att.collect do |a|
        type = a.keys.first
        klass = Viewpoint::EWS::Types.const_get(camel_case(type))
        item = OpenStruct.new
        item.ews = nil
        klass.new(item, a[type])
      end
    end

  end # CreateAttachmentResponseMessage

end # Viewpoint::EWS::SOAP
