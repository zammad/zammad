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

require 'ews/item_accessors'

module Viewpoint::EWS::Types
  module GenericFolder
    include Viewpoint::EWS
    include Viewpoint::EWS::Types
    include Viewpoint::EWS::ItemAccessors
    include Viewpoint::StringUtils

    GFOLDER_KEY_PATHS = {
      :folder_id        => [:folder_id, :attribs],
      :id               => [:folder_id, :attribs, :id],
      :change_key       => [:folder_id, :attribs, :change_key],
      :parent_folder_id => [:parent_folder_id, :attribs, :id],
      :parent_folder_change_key => [:parent_folder_id, :attribs, :change_key],
      :folder_class     => [:folder_class, :text],
      :total_count      => [:total_count, :text],
      :child_folder_count => [:child_folder_count, :text],
      :display_name     => [:display_name, :text],
    }

    GFOLDER_KEY_TYPES = {
      :total_count        => ->(str){str.to_i},
      :child_folder_count => ->(str){str.to_i},
    }

    GFOLDER_KEY_ALIAS = {
      :name   => :display_name,
      :ckey   => :change_key,
    }

    attr_accessor :subscription_id, :watermark, :sync_state

    # @param [SOAP::ExchangeWebService] ews the EWS reference
    # @param [Hash] ews_item the EWS parsed response document
    def initialize(ews, ews_item)
      super
      simplify!
      @sync_state = nil
      @synced = false
    end

    def delete!
      opts = {
        :folder_ids   => [:id => id],
        :delete_type  => 'HardDelete'
      }
      resp = @ews.delete_folder(opts)
      if resp.success?
        true
      else
        raise EwsError, "Could not delete folder. #{resp.code}: #{resp.message}"
      end
    end

    def items(opts = {})
      args = items_args(opts.clone)
      obj = OpenStruct.new(opts: args, restriction: {})
      yield obj if block_given?
      merge_restrictions! obj
      resp = ews.find_item(args)
      items_parser resp
    end

    # Fetch items since a give DateTime
    # @param [DateTime] date_time the time to fetch Items since.
    def items_since(date_time, opts = {})
      opts = opts.clone
      unless date_time.kind_of?(Date)
        raise EwsBadArgumentError, "First argument must be a Date or DateTime"
      end
      restr = {:restriction =>
        {:is_greater_than_or_equal_to =>
          [{:field_uRI => {:field_uRI=>'item:DateTimeReceived'}},
            {:field_uRI_or_constant =>{:constant => {:value=>date_time.to_datetime}}}]
        }}
        items(opts.merge(restr))
    end

    # Fetch only items from today (since midnight)
    def todays_items(opts = {})
      items_since(Date.today)
    end

    # Fetch items between a given time period
    # @param [DateTime] start_date the time to start fetching Items from
    # @param [DateTime] end_date the time to stop fetching Items from
    def items_between(start_date, end_date, opts={})
      items do |obj|
        obj.restriction = { :and =>
          [
            {:is_greater_than_or_equal_to =>
              [
                {:field_uRI => {:field_uRI=>'item:DateTimeReceived'}},
                {:field_uRI_or_constant=>{:constant => {:value =>start_date}}}
              ]
            },
            {:is_less_than_or_equal_to =>
              [
                {:field_uRI => {:field_uRI=>'item:DateTimeReceived'}},
                {:field_uRI_or_constant=>{:constant => {:value =>end_date}}}
              ]
            }
          ]
        }
      end
    end

    # Search on the item subject
    # @param [String] match_str A simple string paramater to match against the
    #   subject.  The search ignores case and does not accept regexes... only strings.
    # @param [String,nil] exclude_str A string to exclude from matches against
    #   the subject.  This is optional.
    def search_by_subject(match_str, exclude_str = nil)
      items do |obj|
        match = {:contains => {
          :containment_mode => 'Substring',
          :containment_comparison => 'IgnoreCase',
          :field_uRI => {:field_uRI=>'item:Subject'},
          :constant => {:value =>match_str}
        }}
        unless exclude_str.nil?
          excl = {:not =>
            {:contains => {
              :containment_mode => 'Substring',
              :containment_comparison => 'IgnoreCase',
              :field_uRI => {:field_uRI=>'item:Subject'},
              :constant => {:value =>exclude_str}
            }}
          }

          match[:and] = [{:contains => match.delete(:contains)}, excl]
        end
        obj.restriction = match
      end
    end

    def get_all_properties!
      @ews_item = get_folder(:base_shape => 'AllProperties')
      simplify!
    end

    def available_categories
      opts = {
        user_config_name: {
          name: 'CategoryList',
          distinguished_folder_id: {id: :calendar}
        },
        user_config_props: 'XmlData'
      }
      resp = ews.get_user_configuration(opts)
      #txt = resp.response_message[:elems][:get_user_configuration_response_message][:elems][1][:user_configuration][:elems][1][:xml_data][:text]
      #Base64.decode64 txt
    end

    # Syncronize Items in this folder. If this method is issued multiple
    # times it will continue where the last sync completed.
    # @param [Integer] sync_amount The number of items to synchronize per sync
    # @param [Boolean] sync_all Whether to sync all the data by looping through.
    #   The default is to just sync the first set.  You can manually loop through
    #   with multiple calls to #sync_items!
    # @return [Hash] Returns a hash with keys for each change type that ocurred.
    #   Possible key values are:
    #     (:create/:udpate/:delete/:read_flag_change).
    #   For :deleted and :read_flag_change items a simple hash with :id and
    #   :change_key is returned.
    #   See: http://msdn.microsoft.com/en-us/library/aa565609.aspx
    def sync_items!(sync_state = nil, sync_amount = 256, sync_all = false, opts = {})
      item_shape = opts.has_key?(:item_shape) ? opts.delete(:item_shape) : {:base_shape => :default}
      sync_state ||= @sync_state

      resp = ews.sync_folder_items item_shape: item_shape,
        sync_folder_id: self.folder_id, max_changes_returned: sync_amount, sync_state: sync_state
      rmsg = resp.response_messages[0]

      if rmsg.success?
        @synced = rmsg.includes_last_item_in_range?
        @sync_state = rmsg.sync_state
        rhash = {}
        rmsg.changes.each do |c|
          ctype = c.keys.first
          rhash[ctype] = [] unless rhash.has_key?(ctype)
          if ctype == :delete || ctype == :read_flag_change
            rhash[ctype] << c[ctype][:elems][0][:item_id][:attribs]
          else
            type = c[ctype][:elems][0].keys.first
            item = class_by_name(type).new(ews, c[ctype][:elems][0][type])
            rhash[ctype] << item
          end
        end
        rhash
      else
        raise EwsError, "Could not synchronize: #{rmsg.code}: #{rmsg.message_text}"
      end
    end

    def synced?
      @synced
    end

    # Subscribe this folder to events.  This method initiates an Exchange pull
    # type subscription.
    #
    # @param event_types [Array] Which event types to subscribe to. By default
    #   we subscribe to all Exchange event types: :all, :copied, :created,
    #   :deleted, :modified, :moved, :new_mail, :free_busy_changed
    # @param watermark [String] pass a watermark if you wish to start the
    #   subscription at a specific point.
    # @param timeout [Fixnum] the time in minutes that the subscription can
    #   remain idle between calls to #get_events. default: 240 minutes
    # @return [Boolean] Did the subscription happen successfully?
    def subscribe(evtypes = [:all], watermark = nil, timeout = 240)
      # Refresh the subscription if already subscribed
      unsubscribe if subscribed?

      event_types = normalize_event_names(evtypes)
      folder = {id: self.id, change_key: self.change_key}
      resp = ews.pull_subscribe_folder(folder, event_types, timeout, watermark)
      rmsg = resp.response_messages.first
      if rmsg.success?
        @subscription_id = rmsg.subscription_id
        @watermark = rmsg.watermark
        true
      else
        raise EwsSubscriptionError, "Could not subscribe: #{rmsg.code}: #{rmsg.message_text}"
      end
    end

    def push_subscribe(url, evtypes = [:all], watermark = nil, status_frequency = nil)

      event_types = normalize_event_names(evtypes)
      folder = {id: self.id, change_key: self.change_key}
      resp = ews.push_subscribe_folder(folder, event_types, url, status_frequency, watermark)
      rmsg = resp.response_messages.first
      if rmsg.success?
        @subscription_id = rmsg.subscription_id
        @watermark = rmsg.watermark
        true
      else
        raise EwsSubscriptionError, "Could not subscribe: #{rmsg.code}: #{rmsg.message_text}"
      end
    end

    # Check if there is a subscription for this folder.
    # @return [Boolean] Are we subscribed to this folder?
    def subscribed?
      ( @subscription_id.nil? or @watermark.nil? )? false : true
    end

    # Unsubscribe this folder from further Exchange events.
    # @return [Boolean] Did we unsubscribe successfully?
    def unsubscribe
      return true if @subscription_id.nil?

      resp = ews.unsubscribe(@subscription_id)
      rmsg = resp.response_messages.first
      if rmsg.success?
        @subscription_id, @watermark = nil, nil
        true
      else
        raise EwsSubscriptionError, "Could not unsubscribe: #{rmsg.code}: #{rmsg.message_text}"
      end
    end

    # Checks a subscribed folder for events
    # @return [Array] An array of Event items
    def get_events
      begin
        if subscribed?
          resp = ews.get_events(@subscription_id, @watermark)
          rmsg = resp.response_messages[0]
          @watermark = rmsg.new_watermark
          # @todo if parms[:more_events] # get more events
          rmsg.events.collect{|ev|
            type = ev.keys.first
            class_by_name(type).new(ews, ev[type])
          }
        else
          raise EwsSubscriptionError, "Folder <#{self.display_name}> not subscribed to. Issue a Folder#subscribe before checking events."
        end
      rescue EwsSubscriptionTimeout => e
        @subscription_id, @watermark = nil, nil
        raise e
      end
    end


    private


    def key_paths
      @key_paths ||= super.merge(GFOLDER_KEY_PATHS)
    end

    def key_types
      @key_types ||= super.merge(GFOLDER_KEY_TYPES)
    end

    def key_alias
      @key_alias ||= super.merge(GFOLDER_KEY_ALIAS)
    end

    def simplify!
      @ews_item = @ews_item[:elems].inject({}) do |o,i|
        key = i.keys.first
        if o.has_key?(key)
          if o[key].is_a?(Array)
            o[key] << i[key]
          else
            o[key] = [o.delete(key), i[key]]
          end
        else
          o[key] = i[key]
        end
        o
      end
    end

    # Get a specific folder by its ID.
    # @param [Hash] opts Misc options to control request
    # @option opts [String] :base_shape IdOnly/Default/AllProperties
    # @raise [EwsError] raised when the backend SOAP method returns an error.
    def get_folder(opts = {})
      args = get_folder_args(opts)
      resp = ews.get_folder(args)
      get_folder_parser(resp)
    end

    # Build up the arguements for #get_folder
    # @todo: should we really pass the ChangeKey or do we want the freshest obj?
    def get_folder_args(opts)
      opts[:base_shape] ||= 'Default'
      default_args = {
        :folder_ids   => [{:id => self.id, :change_key => self.change_key}],
        :folder_shape => {:base_shape => opts[:base_shape]}
      }
      default_args.merge(opts)
    end

    def get_folder_parser(resp)
      if(resp.status == 'Success')
        f = resp.response_message[:elems][:folders][:elems][0]
        f.values.first
      else
        raise EwsError, "Could not retrieve folder. #{resp.code}: #{resp.message}"
      end
    end

    def items_args(opts)
      default_args = {
        :parent_folder_ids => [{:id => self.id}],
        :traversal => 'Shallow',
        :item_shape  => {:base_shape => 'Default'}
      }.merge(opts)
    end

    def items_parser(resp)
      rm = resp.response_messages[0]
      if(rm.status == 'Success')
        items = []
        rm.root_folder.items.each do |i|
          type = i.keys.first
          items << class_by_name(type).new(ews, i[type], self)
        end
        items
      else
        raise EwsError, "Could not retrieve folder. #{rm.code}: #{rm.message_text}"
      end
    end

    def merge_restrictions!(obj, merge_type = :and)
      if obj.opts[:restriction] && !obj.opts[:restriction].empty? && !obj.restriction.empty?
        obj.opts[:restriction] = {
          merge_type => [
            obj.opts.delete(:restriction),
            obj.restriction
        ]
        }
      elsif !obj.restriction.empty?
        obj.opts[:restriction] = obj.restriction
      end
    end

    def normalize_event_names(events)
      if events.include?(:all)
        events = [:copied, :created, :deleted, :modified, :moved, :new_mail, :free_busy_changed]
      end

      events.collect do |ev|
        nev = ruby_case(ev)
        if nev.end_with?('_event')
          nev.to_sym
        else
          "#{nev}_event".to_sym
        end
      end
    end

  end
end
