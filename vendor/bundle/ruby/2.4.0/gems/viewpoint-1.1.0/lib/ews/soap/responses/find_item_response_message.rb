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

  class RootFolder

    attr_reader :root

    def initialize(root)
      @root = root
    end

    def indexed_paging_offset
      attrib :index_paging_offset
    end

    def numerator_offset
      attrib :numerator_offset
    end

    def absolute_denominator
      attrib :absolute_denominator
    end

    def includes_last_item_in_range
      attrib :includes_last_item_in_range
    end

    def total_items_in_view
      attrib :total_items_in_view
    end

    def items
      root[:elems][0][:items][:elems] || []
    end

    def groups
      root[:elems][0][:groups][:elems]
    end


    private
    

    def attrib(key)
      return nil unless root.has_key?(:attribs)
      root[:attribs][key]
    end

  end


  class FindItemResponseMessage < ResponseMessage

    def root_folder
      return @root_folder if @root_folder

      rf = safe_hash_access message, [:elems, :root_folder]
      @root_folder = rf.nil? ? nil : RootFolder.new(rf)
    end

  end # FindItemResponseMessage

end # Viewpoint::EWS::SOAP
