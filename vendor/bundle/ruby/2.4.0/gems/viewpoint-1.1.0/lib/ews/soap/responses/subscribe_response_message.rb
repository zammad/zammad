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
  class SubscribeResponseMessage < ResponseMessage

    def subscription
      safe_hash_access message, [:elems]
    end

    def subscription_id
      safe_hash_access subscription, [:subscription_id, :text]
    end

    def watermark
      safe_hash_access subscription, [:watermark, :text]
    end

  end # SubscribeResponseMessage
end # Viewpoint::EWS::SOAP
