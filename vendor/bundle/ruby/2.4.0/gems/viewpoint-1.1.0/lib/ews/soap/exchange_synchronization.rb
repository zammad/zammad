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

  # Exchange Synchronization operations as listed in the EWS Documentation.
  # @see http://msdn.microsoft.com/en-us/library/bb409286.aspx
  module ExchangeSynchronization
    include Viewpoint::EWS::SOAP

    # Defines a request to synchronize a folder hierarchy on a client
    # @see http://msdn.microsoft.com/en-us/library/aa580990.aspx
    # @param [Hash] opts
    # @option opts [Hash] :folder_shape The folder shape properties
    #   Ex: {:base_shape => 'Default', :additional_properties => 'bla bla bla'}
    # @option opts [Hash] :sync_folder_id An optional Hash that represents a FolderId or
    #   DistinguishedFolderId.
    #   Ex: {:id => :inbox}
    # @option opts [Hash] :sync_state The Base64 sync state id. If this is the
    #   first time syncing this does not need to be passed.
    def sync_folder_hierarchy(opts)
      opts = opts.clone
      req = build_soap! do |type, builder|
        if(type == :header)
        else
          builder.nbuild.SyncFolderHierarchy {
            builder.nbuild.parent.default_namespace = @default_ns
            builder.folder_shape!(opts[:folder_shape])
            builder.sync_folder_id!(opts[:sync_folder_id]) if opts[:sync_folder_id]
            builder.sync_state!(opts[:sync_state]) if opts[:sync_state]
          }
        end
      end
      do_soap_request(req, response_class: EwsResponse)
    end

    # Synchronizes items between the Exchange server and the client
    # @see http://msdn.microsoft.com/en-us/library/aa563967(v=EXCHG.140).aspx
    # @param [Hash] opts
    # @option opts [Hash] :item_shape The item shape properties
    #   Ex: {:base_shape => 'Default', :additional_properties => 'bla bla bla'}
    # @option opts [Hash] :sync_folder_id A Hash that represents a FolderId or
    #   DistinguishedFolderId. [ Ex: {:id => :inbox} ] OPTIONAL
    # @option opts [String] :sync_state The Base64 sync state id. If this is the
    #   first time syncing this does not need to be passed. OPTIONAL on first call
    # @option opts [Array <String>] :ignore An Array of ItemIds for items to ignore
    #   during the sync process. Ex: [{:id => 'id1', :change_key => 'ck'}, {:id => 'id2'}]
    #   OPTIONAL
    # @option opts [Integer] :max_changes_returned ('required') The amount of items to sync per call.
    # @option opts [String] :sync_scope specifies whether just items or items and folder associated
    #   information are returned. OPTIONAL
    #   options: 'NormalItems' or 'NormalAndAssociatedItems'
    # @example
    #   { :item_shape => {:base_shape => 'Default'},
    #     :sync_folder_id => {:id => :inbox},
    #     :sync_state => myBase64id,
    #     :max_changes_returned => 256 }
    def sync_folder_items(opts)
      opts = opts.clone
      req = build_soap! do |type, builder|
        if(type == :header)
        else
          builder.nbuild.SyncFolderItems {
            builder.nbuild.parent.default_namespace = @default_ns
            builder.item_shape!(opts[:item_shape])
            builder.sync_folder_id!(opts[:sync_folder_id]) if opts[:sync_folder_id]
            builder.sync_state!(opts[:sync_state]) if opts[:sync_state]
            builder.ignore!(opts[:ignore]) if opts[:ignore]
            builder.max_changes_returned!(opts[:max_changes_returned])
            builder.sync_scope!(opts[:sync_scope]) if opts[:sync_scope]
          }
        end
      end
      do_soap_request(req, response_class: EwsResponse)
    end

  end #ExchangeSynchronization
end
