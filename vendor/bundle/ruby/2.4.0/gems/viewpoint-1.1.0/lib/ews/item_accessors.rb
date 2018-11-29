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
module Viewpoint::EWS::ItemAccessors
  include Viewpoint::EWS

  # This is a class method that fetches an existing Item from the
  #  Exchange Store.
  # @param [String] item_id The id of the item. You can also pass a Hash in the
  #   form: {id: <fold_id>, change_key: <change_key>}
  # @param [Hash] opts Misc options to control request
  # @option opts [Symbol] :shape :id_only/:default/:all_properties
  # @return [Item] Returns an Item or subclass of Item
  # @todo Add support to fetch an item with a ChangeKey
  def get_item(item_id, opts = {})
    args = get_item_args(item_id, opts.clone)
    obj = OpenStruct.new(opts: args)
    yield obj if block_given?
    resp = ews.get_item(args)
    get_item_parser(resp)
  end

  # @param [Hash] opts Misc options to control request
  # @option opts [Symbol] :folder_id
  # @see GenericFolder#items
  def find_items(opts = {})
    args = find_items_args(opts.clone)
    obj = OpenStruct.new(opts: args, restriction: {})
    yield obj if block_given?
    merge_restrictions! obj
    resp = ews.find_item(args)
    find_items_parser resp
  end

  # This is a class method that fetches an existing Item from the
  #  Exchange Store.
  # @param [String] item_id The id of the item. You can also pass a Hash in the
  #   form: {id: <fold_id>, change_key: <change_key>}
  # @param [Hash] opts Misc options to control request
  # @option opts [Symbol] :shape :id_only/:default/:all_properties
  # @return [Item] Returns an Item or subclass of Item
  # @todo Add support to fetch an item with a ChangeKey
  def get_items(item_ids, opts = {})
    args = get_item_args(item_ids, opts.clone)
    obj = OpenStruct.new(opts: args)
    yield obj if block_given?
    resp = ews.get_item(args)
    get_items_parser(resp)
  end

  # Copy an array of items to the specified folder
  # @param items [Array] an array of EWS Items that you want to copy
  # @param folder [String,Symbol,GenericFolder] The folder to copy to. This must
  #   be a subclass of GenericFolder, a DistinguishedFolderId (must me a Symbol)
  #   or a FolderId (String)
  # @return [Array<Hash>] returns a Hash for each item passed
  #   on success:
  #     {:success => true, :item_id => <new_item_id>}
  #   on failure:
  #     {:success => false, :error_message => <the message>}
  def copy_items(items, folder)
    folder = folder.id if folder.kind_of?(Types::GenericFolder)
    item_ids = items.collect{|i| {item_id: {id: i.id, change_key: i.change_key}}}
    copy_opts = {
      :to_folder_id => {:id => folder},
      :item_ids => item_ids
    }
    resp = ews.copy_item(copy_opts)
    copy_move_items_parser(resp)
  end

  # Move an array of items to the specified folder
  # @see #copy_items for parameter info
  def move_items(items, folder)
    folder = folder.id if folder.kind_of?(Types::GenericFolder)
    item_ids = items.collect{|i| {item_id: {id: i.id, change_key: i.change_key}}}
    move_opts = {
      :to_folder_id => {:id => folder},
      :item_ids => item_ids
    }
    resp = ews.move_item(move_opts)
    copy_move_items_parser(resp, :move_item_response_message)
  end

  # Exports an entire item into base64 string
  # @param item_ids [Array] array of item ids. Can also be a single id value
  # return [Array] array of bulk items
  def export_items(item_ids)
    args = export_items_args(item_ids)

    resp = ews.export_items(args)
    export_items_parser(resp)
  end

private

  def get_item_args(item_id, opts)
    opts[:shape] ||= :default
    default_args = {
      :item_shape => {:base_shape => opts[:shape]}
    }
    default_args[:item_ids] = case item_id
    when Hash
      [{:item_id => item_id}]
    when Array
      item_id.map{|i| {:item_id => {:id => i}}}
    else
      [{:item_id => {:id => item_id}}]
    end
    default_args.merge opts
  end

  def get_item_parser(resp)
    rm = resp.response_messages[0]

    if(rm && rm.status == 'Success')
      i = rm.items.first
      itype = i.keys.first
      class_by_name(itype).new(ews, i[itype])
    else
      code = rm.respond_to?(:code) ? rm.code : "Unknown"
      text = rm.respond_to?(:message_text) ? rm.message_text : "Unknown"
      raise EwsItemNotFound, "Could not retrieve item. #{rm.code}: #{rm.message_text}"
    end
  end

  def get_items_parser(resp)
    items = []

    resp.response_messages.each do |rm|
      if(rm && rm.status == 'Success')
        rm.items.each do |i|
          type = i.keys.first
          items << class_by_name(type).new(ews, i[type])
        end
      end
    end

    items
  end

  def find_items_args(opts)
    default_args = {
      :traversal => 'Shallow',
      :item_shape  => {:base_shape => 'Default'}
    }

    if opts[:folder_id].is_a?(Hash)
      default_args[:parent_folder_ids] = [opts.delete(:folder_id)]
    else
      default_args[:parent_folder_ids] = [{:id => opts.delete(:folder_id)}]
    end
    default_args.merge(opts)
  end

  def find_items_parser(resp)
    rm = resp.response_messages[0]
    if rm.success?
      items = []
      rm.root_folder.items.each do |i|
        type = i.keys.first
        items << class_by_name(type).new(ews, i[type])
      end
      items
    else
      raise EwsError, "Could not retrieve folder. #{rm.code}: #{rm.message_text}"
    end
  end

  def copy_move_items_parser(resp, resp_type = :copy_item_response_message)
    resp.response_messages.collect {|r|
      obj = {}
      if r.success?
        obj[:success] = true
        item = r.items.first
        key = item.keys.first
        obj[:item_id] = item[key][:elems][0][:item_id][:attribs][:id]
      else
        obj[:success] = false
        obj[:error_message] = "#{r.response_code}: #{r.message_text}"
      end
      obj
    }
  end

  def export_items_args(item_ids)
    default_args = {}
    default_args[:item_ids] = []
    if item_ids.is_a?(Array) then
      item_ids.each do |id|
        default_args[:item_ids] = default_args[:item_ids] + [{:item_id => {:id => id}}]
      end
    else
      default_args[:item_ids] = [{:item_id => {:id => item_ids}}]
    end
    default_args
  end

  def export_items_parser(resp)
    rm = resp.response_messages
    if(rm)
      items = []
      rm.each do |i|
        if i.success? then
          type = i.type
          items << class_by_name(type).new(ews, i.message[:elems])
        else
          code = i.respond_to?(:code) ? i.code : "Unknown"
          text = i.respond_to?(:message_text) ? i.message_text : "Unknown"
          items << "Could not retrieve item. #{code}: #{text}"
        end
      end
    items
    end
  end

end # Viewpoint::EWS::ItemAccessors
