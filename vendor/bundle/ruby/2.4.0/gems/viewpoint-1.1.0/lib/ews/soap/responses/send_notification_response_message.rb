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
  class SendNotificationResponseMessage < ResponseMessage
    include Viewpoint::StringUtils

    def notification
      safe_hash_access message, [:elems, :notification, :elems]
    end

    def subscription_id
      safe_hash_access notification[0], [:subscription_id, :text]
    end

    def previous_watermark
      safe_hash_access notification[1], [:previous_watermark, :text]
    end

    def new_watermark
      ev = notification.last
      if ev
        type = ev.keys.first
        ev[type][:elems][0][:watermark][:text]
      else
        nil
      end
    end

    def more_events?
      safe_hash_access(notification[2], [:more_events, :text]) == 'true'
    end

    def events
      @events ||=
        notification[3..-1].collect do |ev|
          type = ev.keys.first
          klass = Viewpoint::EWS::Types.const_get(camel_case(type))
          klass.new(nil, ev[type])
        end
    end

  end # SendNotificationResponseMessage
end # Viewpoint::EWS::SOAP
