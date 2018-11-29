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
  # A generic Attachment.  This class should not be instantiated directly.  You
  # should use one of the subclasses like FileAttachment or ItemAttachment.
  class Attachment
    include Viewpoint::EWS
    include Viewpoint::EWS::Types
    include Viewpoint::EWS::Types::Item

    ATTACH_KEY_PATHS = {
      :id   => [:attachment_id, :attribs, :id],
      :parent_item_id  => [:attachment_id, :attribs, :root_item_id],
      :parent_change_key  => [:attachment_id, :attribs, :root_item_change_key],
      :name => [:name, :text],
      :content_type => [:content_type, :text],
      :content_id => [:content_id],
      :size => [:size, :text],
      :last_modified_time => [:last_modified_time, :text],
      :is_inline? => [:is_inline, :text],
    }

    ATTACH_KEY_TYPES = {
      is_inline?:   ->(str){str.downcase == 'true'},
      last_modified_type: ->(str){DateTime.parse(str)},
      size: ->(str){str.to_i},
      content_id: :fix_content_id,
    }

    ATTACH_KEY_ALIAS = { }

    # @param [Hash] attachment The attachment ews_item
    def initialize(item, attachment)
      @item = item
      super(item.ews, attachment)
    end


    private


    def key_paths
      @key_paths ||= ATTACH_KEY_PATHS
    end

    def key_types
      @key_types ||= ATTACH_KEY_TYPES
    end

    def key_alias
      @key_alias ||= ATTACH_KEY_ALIAS
    end

    # Sometimes the SOAP response comes back with two identical content_ids.
    # This method fishes them out no matter which way them come.
    def fix_content_id(content_id)
      content_id.is_a?(Array) ? content_id.last[:text] : content_id[:text]
    end

  end
end
