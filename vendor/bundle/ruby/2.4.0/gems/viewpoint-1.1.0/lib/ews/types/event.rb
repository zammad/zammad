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

module Viewpoint::EWS::Types

  class Event
    include Viewpoint::EWS
    include Viewpoint::EWS::Types
    include Viewpoint::EWS::Types::Item

    EVENT_KEY_PATHS = {
      :watermark  => [:watermark, :text],
      :timestamp  => [:time_stamp, :text],
      :item_id    => [:item_id, :attribs],
      :folder_id  => [:folder_id, :attribs],
      :parent_folder_id  => [:parent_folder_id, :attribs],
    }

    EVENT_KEY_TYPES = {
      :timestamp  => ->(ts){ DateTime.iso8601(ts) }
    }

    EVENT_KEY_ALIAS = { }

    def initialize(ews, event)
      @ews = ews
      super(ews, event)
    end


    private


    def key_paths
      @key_paths ||= EVENT_KEY_PATHS
    end

    def key_types
      @key_types ||= EVENT_KEY_TYPES
    end

    def key_alias
      @key_alias ||= EVENT_KEY_ALIAS
    end

  end
end
