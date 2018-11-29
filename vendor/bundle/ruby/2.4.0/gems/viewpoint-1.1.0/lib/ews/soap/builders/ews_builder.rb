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

  # This class includes the element builders. The idea is that each element should
  # know how to build themselves so each parent element can delegate creation of
  # subelements to a method of the same name with a '!' after it.
  class EwsBuilder
    include Viewpoint::EWS
    include Viewpoint::StringUtils

    attr_reader :nbuild
    def initialize
      @nbuild = Nokogiri::XML::Builder.new
    end

    # Build the SOAP envelope and yield this object so subelements can be built. Once
    # you have the EwsBuilder object you can use the nbuild object like shown in the
    # example for the Header section. The nbuild object is the underlying
    # Nokogiri::XML::Builder object.
    # @param [Hash] opts
    # @option opts [String] :server_version The version string that should get
    #   set in the Header. See ExchangeWebService#initialize
    # @option opts [Hash] :time_zone_context TimeZoneDefinition. Format: !{id: time_zone_identifier}
    # @example
    #   xb = EwsBuilder.new
    #   xb.build! do |part, b|
    #     if(part == :header)
    #       b.nbuild.MyVar('blablabla')
    #     else
    #       b.folder_shape!({:base_shape => 'Default'})
    #     end
    #   end
    def build!(opts = {}, &block)
      @nbuild.Envelope(NAMESPACES) do |node|
        node.parent.namespace = parent_namespace(node)
        node.Header {
          set_version_header! opts[:server_version]
          set_impersonation! opts[:impersonation_type], opts[:impersonation_mail]
          set_time_zone_context_header! opts[:time_zone_context]
          yield(:header, self) if block_given?
        }
        node.Body {
          yield(:body, self) if block_given?
        }
      end
      @nbuild.doc
    end

    # Build XML from a passed in Hash or Array in a specified format.
    # @param [Array,Hash] elems The elements to add to the Builder. They must
    #   be specified like so:
    #
    #   !{:top =>
    #     { :xmlns => 'http://stonesthrow/soap',
    #       :sub_elements => [
    #         {:elem1 => {:text => 'inside'}},
    #         {:elem2 => {:text => 'inside2'}}
    #       ],
    #       :id => '3232', :tx_dd => 23, :asdf => 'turkey'
    #     }
    #   }
    #   or
    #   [ {:first => {:text => 'hello'}},
    #     {:second => {:text => 'world'}}
    #   ]
    #
    #   NOTE: there are specialized keys for text (:text), child elements
    #   (:sub_elements) and namespaces (:xmlns).
    def build_xml!(elems)
      case elems.class.name
      when 'Hash'
        keys = elems.keys
        vals = elems.values
        if(keys.length > 1 && !vals.is_a?(Hash))
          raise "invalid input: #{elems}"
        end
        vals = vals.first.clone
        se = vals.delete(:sub_elements)
        txt = vals.delete(:text)
        xmlns_attribute = vals.delete(:xmlns_attribute)

        node = @nbuild.send(camel_case(keys.first), txt, vals) {|x|
          build_xml!(se) if se
        }

        # Set node level namespace
        node.xmlns = NAMESPACES["xmlns:#{xmlns_attribute}"] if xmlns_attribute
      when 'Array'
        elems.each do |e|
          build_xml!(e)
        end
      else
        raise "Unsupported type: #{elems.class.name}"
      end
    end

    # Build the FolderShape element
    # @see http://msdn.microsoft.com/en-us/library/aa494311.aspx
    # @param [Hash] folder_shape The folder shape structure to build from
    # @todo need fully support all options
    def folder_shape!(folder_shape)
      @nbuild.FolderShape {
        @nbuild.parent.default_namespace = @default_ns
        base_shape!(folder_shape[:base_shape])
        if(folder_shape[:additional_properties])
          additional_properties!(folder_shape[:additional_properties])
        end
      }
    end

    # Build the ItemShape element
    # @see http://msdn.microsoft.com/en-us/library/aa565261.aspx
    # @param [Hash] item_shape The item shape structure to build from
    # @todo need fully support all options
    def item_shape!(item_shape)
      @nbuild[NS_EWS_MESSAGES].ItemShape {
        @nbuild.parent.default_namespace = @default_ns
        base_shape!(item_shape[:base_shape])
        mime_content!(item_shape[:include_mime_content]) if item_shape.has_key?(:include_mime_content)
        body_type!(item_shape[:body_type]) if item_shape[:body_type]
        if(item_shape[:additional_properties])
          additional_properties!(item_shape[:additional_properties])
        end
      }
    end

    # Build the IndexedPageItemView element
    # @see http://msdn.microsoft.com/en-us/library/exchange/aa563549(v=exchg.150).aspx
    # @todo needs peer check
    def indexed_page_item_view!(indexed_page_item_view)
      attribs = {}
      indexed_page_item_view.each_pair {|k,v| attribs[camel_case(k)] = v.to_s}
      @nbuild[NS_EWS_MESSAGES].IndexedPageItemView(attribs)
    end

    # Build the BaseShape element
    # @see http://msdn.microsoft.com/en-us/library/aa580545.aspx
    def base_shape!(base_shape)
      @nbuild[NS_EWS_TYPES].BaseShape(camel_case(base_shape))
    end

    def mime_content!(include_mime_content)
      @nbuild[NS_EWS_TYPES].IncludeMimeContent(include_mime_content.to_s.downcase)
    end

    def body_type!(body_type)
      body_type = body_type.to_s
      if body_type =~ /html/i
        body_type = body_type.upcase
      else
        body_type = body_type.downcase.capitalize
      end
      nbuild[NS_EWS_TYPES].BodyType(body_type)
    end

    # Build the ParentFolderIds element
    # @see http://msdn.microsoft.com/en-us/library/aa565998.aspx
    def parent_folder_ids!(pfids)
      @nbuild[NS_EWS_MESSAGES].ParentFolderIds {
        pfids.each do |pfid|
          dispatch_folder_id!(pfid)
        end
      }
    end

    # Build the ParentFolderId element
    # @see http://msdn.microsoft.com/en-us/library/aa563268.aspx
    def parent_folder_id!(pfid)
      @nbuild.ParentFolderId {
        dispatch_folder_id!(pfid)
      }
    end

    # Build the FolderIds element
    # @see http://msdn.microsoft.com/en-us/library/aa580509.aspx
    def folder_ids!(fids, act_as=nil)
      ns = @nbuild.parent.name.match(/subscription/i) ? NS_EWS_TYPES : NS_EWS_MESSAGES
      @nbuild[ns].FolderIds {
        fids.each do |fid|
          fid[:act_as] = act_as if act_as != nil
          dispatch_folder_id!(fid)
        end
      }
    end

    # Build the SyncFolderId element
    # @see http://msdn.microsoft.com/en-us/library/aa580296.aspx
    def sync_folder_id!(fid)
      @nbuild.SyncFolderId {
        dispatch_folder_id!(fid)
      }
    end

    # Build the DistinguishedFolderId element
    # @see http://msdn.microsoft.com/en-us/library/aa580808.aspx
    # @todo add support for the Mailbox child object
    def distinguished_folder_id!(dfid, change_key = nil, act_as = nil)
      attribs = {'Id' => dfid.to_s}
      attribs['ChangeKey'] = change_key if change_key
      @nbuild[NS_EWS_TYPES].DistinguishedFolderId(attribs) {
        if ! act_as.nil?
          mailbox!({:email_address => act_as})
        end
      }
    end

    # Build the FolderId element
    # @see http://msdn.microsoft.com/en-us/library/aa579461.aspx
    def folder_id!(fid, change_key = nil)
      attribs = {'Id' => fid}
      attribs['ChangeKey'] = change_key if change_key
      @nbuild[NS_EWS_TYPES].FolderId(attribs)
    end

    # @see http://msdn.microsoft.com/en-us/library/aa563525(v=EXCHG.140).aspx
    def item_ids!(item_ids)
      @nbuild.ItemIds {
        item_ids.each do |iid|
          dispatch_item_id!(iid)
        end
      }
    end

    def parent_item_id!(id)
      nbuild.ParentItemId {|x|
        x.parent['Id'] = id[:id]
        x.parent['ChangeKey'] = id[:change_key] if id[:change_key]
      }
    end

    # @see http://msdn.microsoft.com/en-us/library/aa580234(v=EXCHG.140).aspx
    def item_id!(id)
      nbuild[NS_EWS_TYPES].ItemId {|x|
        x.parent['Id'] = id[:id]
        x.parent['ChangeKey'] = id[:change_key] if id[:change_key]
      }
    end

    # @see http://msdn.microsoft.com/en-us/library/ff709503(v=exchg.140).aspx
    def export_item_ids!(item_ids)
      ns = @nbuild.parent.name.match(/subscription/i) ? NS_EWS_TYPES : NS_EWS_MESSAGES
      @nbuild[ns].ExportItems{
        @nbuild.ItemIds {
          item_ids.each do |iid|
            dispatch_item_id!(iid)
          end
        }
      }
    end

    # @see http://msdn.microsoft.com/en-us/library/aa580744(v=EXCHG.140).aspx
    def occurrence_item_id!(id)
      @nbuild[NS_EWS_TYPES].OccurrenceItemId {|x|
        x.parent['RecurringMasterId'] = id[:recurring_master_id]
        x.parent['ChangeKey'] = id[:change_key] if id[:change_key]
        x.parent['InstanceIndex'] = id[:instance_index]
      }
    end

    # @see http://msdn.microsoft.com/en-us/library/aa581019(v=EXCHG.140).aspx
    def recurring_master_item_id!(id)
      @nbuild[NS_EWS_TYPES].RecurringMasterItemId {|x|
        x.parent['OccurrenceId'] = id[:occurrence_id]
        x.parent['ChangeKey'] = id[:change_key] if id[:change_key]
      }
    end

    # @see http://msdn.microsoft.com/en-us/library/aa565020(v=EXCHG.140).aspx
    def to_folder_id!(to_fid)
      @nbuild[NS_EWS_MESSAGES].ToFolderId {
        dispatch_folder_id!(to_fid)
      }
    end

    # @see http://msdn.microsoft.com/en-us/library/aa564009.aspx
    def folders!(folders)
      @nbuild.Folders {|x|
        folders.each do |fold|
          fold.each_pair do |ftype, vars| # convenience, should only be one pair
            ftype = "#{ftype}!".to_sym
            if self.respond_to? ftype
              self.send ftype, vars
            else
              raise Viewpoint::EWS::EwsNotImplemented,
                "#{ftype} not implemented as a builder."
            end
          end
        end
      }
    end

    def folder!(folder, type = :Folder)
      nbuild[NS_EWS_TYPES].send(type) {|x|
        folder.each_pair do |e,v|
          ftype = "#{e}!".to_sym
          if e == :folder_id
            dispatch_folder_id!(v)
          elsif self.respond_to?(ftype)
            self.send ftype, v
          else
            raise Viewpoint::EWS::EwsNotImplemented,
              "#{ftype} not implemented as a builder."
          end
        end
      }
    end

    def calendar_folder!(folder)
      folder! folder, :CalendarFolder
    end

    def contacts_folder!(folder)
      folder! folder, :ContactsFolder
    end

    def search_folder!(folder)
      folder! folder, :SearchFolder
    end

    def tasks_folder!(folder)
      folder! folder, :TasksFolder
    end

    def display_name!(name)
      nbuild[NS_EWS_TYPES].DisplayName(name)
    end

    # Build the AdditionalProperties element
    # @see http://msdn.microsoft.com/en-us/library/aa563810.aspx
    def additional_properties!(addprops)
      @nbuild[NS_EWS_TYPES].AdditionalProperties {
        addprops.each_pair {|k,v|
          dispatch_field_uri!({k => v}, NS_EWS_TYPES)
        }
      }
    end

    # Build the Mailbox element.
    # This element is commonly used for delegation. Typically passing an
    #   email_address is sufficient
    # @see http://msdn.microsoft.com/en-us/library/aa565036.aspx
    # @param [Hash] mailbox A well-formated hash
    def mailbox!(mbox)
      nbuild[NS_EWS_TYPES].Mailbox {
        name!(mbox[:name]) if mbox[:name]
        email_address!(mbox[:email_address]) if mbox[:email_address]
        address!(mbox[:address]) if mbox[:address] # for Availability query
        routing_type!(mbox[:routing_type]) if mbox[:routing_type]
        mailbox_type!(mbox[:mailbox_type]) if mbox[:mailbox_type]
        item_id!(mbox[:item_id]) if mbox[:item_id]
      }
    end

    def name!(name)
      nbuild[NS_EWS_TYPES].Name(name)
    end

    def email_address!(email)
      nbuild[NS_EWS_TYPES].EmailAddress(email)
    end

    def address!(email)
      nbuild[NS_EWS_TYPES].Address(email)
    end

    # This is stupid. The only valid value is "SMTP"
    def routing_type!(type)
      nbuild[NS_EWS_TYPES].RoutingType(type)
    end

    def mailbox_type!(type)Standard
      nbuild[NS_EWS_TYPES].MailboxType(type)
    end

    def user_oof_settings!(opts)
      nbuild[NS_EWS_TYPES].UserOofSettings {
        nbuild.OofState(camel_case(opts[:oof_state]))
        nbuild.ExternalAudience(camel_case(opts[:external_audience])) if opts[:external_audience]
        duration!(opts[:duration]) if opts[:duration]
        nbuild.InternalReply {
          nbuild.Message(opts[:internal_reply])
        } if opts[:external_reply]
        nbuild.ExternalReply {
          nbuild.Message(opts[:external_reply])
        } if opts[:external_reply]
      }
    end

    def duration!(opts)
      nbuild.Duration {
        nbuild.StartTime(format_time opts[:start_time])
        nbuild.EndTime(format_time opts[:end_time])
      }
    end

    def mailbox_data!(md)
      nbuild[NS_EWS_TYPES].MailboxData {
        nbuild[NS_EWS_TYPES].Email {
          mbox = md[:email]
          name!(mbox[:name]) if mbox[:name]
          address!(mbox[:address]) if mbox[:address] # for Availability query
          routing_type!(mbox[:routing_type]) if mbox[:routing_type]
        }
        nbuild[NS_EWS_TYPES].AttendeeType 'Required'
      }
    end

    def free_busy_view_options!(opts)
      nbuild[NS_EWS_TYPES].FreeBusyViewOptions {
        nbuild[NS_EWS_TYPES].TimeWindow {
          nbuild[NS_EWS_TYPES].StartTime(format_time opts[:time_window][:start_time])
          nbuild[NS_EWS_TYPES].EndTime(format_time opts[:time_window][:end_time])
        }
        nbuild[NS_EWS_TYPES].RequestedView(camel_case(opts[:requested_view][:requested_free_busy_view]))
      }
    end

    def suggestions_view_options!(opts)
    end

    def time_zone!(zone)
      zone ||= {}
      zone = {
        bias: zone[:bias] || 480,
        standard_time: {
          bias: 0,
          time: "02:00:00",
          day_order: 5,
          month: 10,
          day_of_week: 'Sunday'
        }.merge(zone[:standard_time] || {}),
        daylight_time: {
          bias: -60,
          time: "02:00:00",
          day_order: 1,
          month: 4,
          day_of_week: 'Sunday'
        }.merge(zone[:daylight_time] || {})
      }

      nbuild[NS_EWS_TYPES].TimeZone {
        nbuild[NS_EWS_TYPES].Bias(zone[:bias])
        nbuild[NS_EWS_TYPES].StandardTime {
          nbuild[NS_EWS_TYPES].Bias(zone[:standard_time][:bias])
          nbuild[NS_EWS_TYPES].Time(zone[:standard_time][:time])
          nbuild[NS_EWS_TYPES].DayOrder(zone[:standard_time][:day_order])
          nbuild[NS_EWS_TYPES].Month(zone[:standard_time][:month])
          nbuild[NS_EWS_TYPES].DayOfWeek(zone[:standard_time][:day_of_week])
        }
        nbuild[NS_EWS_TYPES].DaylightTime {
          nbuild[NS_EWS_TYPES].Bias(zone[:daylight_time][:bias])
          nbuild[NS_EWS_TYPES].Time(zone[:daylight_time][:time])
          nbuild[NS_EWS_TYPES].DayOrder(zone[:daylight_time][:day_order])
          nbuild[NS_EWS_TYPES].Month(zone[:daylight_time][:month])
          nbuild[NS_EWS_TYPES].DayOfWeek(zone[:daylight_time][:day_of_week])
        }
      }
    end

    # Request all known time_zones from server
    def get_server_time_zones!(get_time_zone_options)
      nbuild[NS_EWS_MESSAGES].GetServerTimeZones('ReturnFullTimeZoneData' => get_time_zone_options[:full]) do
        if get_time_zone_options[:ids] && get_time_zone_options[:ids].any?
          nbuild[NS_EWS_MESSAGES].Ids do
            get_time_zone_options[:ids].each do |id|
              nbuild[NS_EWS_TYPES].Id id
            end
          end
        end
      end
    end

    # Specifies an optional time zone for the start time
    # @param [Hash] attributes
    # @option attributes :id [String] ID of the Microsoft well known time zone
    # @option attributes :name [String] Optional name of the time zone
    # @todo Implement sub elements Periods, TransitionsGroups and Transitions to override zone
    # @see http://msdn.microsoft.com/en-us/library/exchange/dd899524.aspx
    def start_time_zone!(zone)
      attributes = {}
      attributes['Id'] = zone[:id] if zone[:id]
      attributes['Name'] = zone[:name] if zone[:name]
      nbuild[NS_EWS_TYPES].StartTimeZone(attributes)
    end

    # Specifies an optional time zone for the end time
    # @param [Hash] attributes
    # @option attributes :id [String] ID of the Microsoft well known time zone
    # @option attributes :name [String] Optional name of the time zone
    # @todo Implement sub elements Periods, TransitionsGroups and Transitions to override zone
    # @see http://msdn.microsoft.com/en-us/library/exchange/dd899434.aspx
    def end_time_zone!(zone)
      attributes = {}
      attributes['Id'] = zone[:id] if zone[:id]
      attributes['Name'] = zone[:name] if zone[:name]
      nbuild[NS_EWS_TYPES].EndTimeZone(attributes)
    end

    # Specify a time zone
    # @todo Implement subelements Periods, TransitionsGroups and Transitions to override zone
    # @see http://msdn.microsoft.com/en-us/library/exchange/dd899488.aspx
    def time_zone_definition!(zone)
      attributes = {'Id' => zone[:id]}
      attributes['Name'] = zone[:name] if zone[:name]
      nbuild[NS_EWS_TYPES].TimeZoneDefinition(attributes)
    end

    # Build the Restriction element
    # @see http://msdn.microsoft.com/en-us/library/aa563791.aspx
    # @param [Hash] restriction a well-formatted Hash that can be fed to #build_xml!
    def restriction!(restriction)
      @nbuild[NS_EWS_MESSAGES].Restriction {
        restriction.each_pair do |k,v|
          self.send normalize_type(k), v
        end
      }
    end

    def and_r(expr)
      and_or('And', expr)
    end

    def or_r(expr)
      and_or('Or', expr)
    end

    def and_or(type, expr)
      @nbuild[NS_EWS_TYPES].send(type) {
        expr.each do |e|
          type = e.keys.first
          self.send normalize_type(type), e[type]
        end
      }
    end

    def not_r(expr)
      @nbuild[NS_EWS_TYPES].Not {
        type = expr.keys.first
        self.send(type, expr[type])
      }
    end

    def contains(expr)
      @nbuild[NS_EWS_TYPES].Contains(
        'ContainmentMode' => expr.delete(:containment_mode),
        'ContainmentComparison' => expr.delete(:containment_comparison)) {
        c = expr.delete(:constant) # remove constant 1st for ordering
        type = expr.keys.first
        self.send(type, expr[type])
        constant(c)
      }
    end

    def excludes(expr)
      @nbuild[NS_EWS_TYPES].Excludes {
        b = expr.delete(:bitmask) # remove bitmask 1st for ordering
        type = expr.keys.first
        self.send(type, expr[type])
        bitmask(b)
      }
    end

    def exists(expr)
      @nbuild[NS_EWS_TYPES].Exists {
        type = expr.keys.first
        self.send(type, expr[type])
      }
    end

    def bitmask(expr)
      @nbuild[NS_EWS_TYPES].Bitmask('Value' => expr[:value])
    end

    def is_equal_to(expr)
      restriction_compare('IsEqualTo',expr)
    end

    def is_greater_than(expr)
      restriction_compare('IsGreaterThan',expr)
    end

    def is_greater_than_or_equal_to(expr)
      restriction_compare('IsGreaterThanOrEqualTo',expr)
    end

    def is_less_than(expr)
      restriction_compare('IsLessThan',expr)
    end

    def is_less_than_or_equal_to(expr)
      restriction_compare('IsLessThanOrEqualTo',expr)
    end

    def is_not_equal_to(expr)
      restriction_compare('IsNotEqualTo',expr)
    end

    def restriction_compare(type,expr)
      nbuild[NS_EWS_TYPES].send(type) {
        expr.each do |e|
          e.each_pair do |k,v|
            self.send(k, v)
          end
        end
      }
    end

    def ews_types_builder
      nbuild[NS_EWS_TYPES]
    end

    def field_uRI(expr)
      value = expr.is_a?(Hash) ? (expr[:field_uRI] || expr[:field_uri]) : expr
      ews_types_builder.FieldURI('FieldURI' => value)
    end

    alias_method :field_uri, :field_uRI

    def indexed_field_uRI(expr)
      nbuild[NS_EWS_TYPES].IndexedFieldURI(
        'FieldURI'    => (expr[:field_uRI] || expr[:field_uri]),
        'FieldIndex'  => expr[:field_index]
      )
    end

    alias_method :indexed_field_uri, :indexed_field_uRI

    def extended_field_uRI(expr)
      nbuild[NS_EWS_TYPES].ExtendedFieldURI {
        nbuild.parent['DistinguishedPropertySetId'] = expr[:distinguished_property_set_id] if expr[:distinguished_property_set_id]
        nbuild.parent['PropertySetId'] = expr[:property_set_id] if expr[:property_set_id]
        nbuild.parent['PropertyTag'] = expr[:property_tag] if expr[:property_tag]
        nbuild.parent['PropertyName'] = expr[:property_name] if expr[:property_name]
        nbuild.parent['PropertyId'] = expr[:property_id] if expr[:property_id]
        nbuild.parent['PropertyType'] = expr[:property_type] if expr[:property_type]
      }
    end

    alias_method :extended_field_uri, :extended_field_uRI

    def extended_properties!(eprops)
      eprops.each {|ep| extended_property!(ep)}
    end

    def extended_property!(eprop)
      nbuild[NS_EWS_TYPES].ExtendedProperty {
        key = eprop.keys.grep(/extended/i).first
        dispatch_field_uri!({key => eprop[key]}, NS_EWS_TYPES)
        if eprop[:values]
          nbuild.Values {
            eprop[:values].each do |v|
                value! v
            end
          }
        elsif eprop[:value]
          value! eprop[:value]
        end
      }
    end

    def value!(val)
      nbuild[NS_EWS_TYPES].Value(val)
    end

    def field_uRI_or_constant(expr)
      nbuild[NS_EWS_TYPES].FieldURIOrConstant {
        type = expr.keys.first
        self.send(type, expr[type])
      }
    end

    alias_method :field_uri_or_constant, :field_uRI_or_constant

    def constant(expr)
      nbuild[NS_EWS_TYPES].Constant('Value' => expr[:value])
    end

    # Build the CalendarView element
    def calendar_view!(cal_view)
      attribs = {}
      cal_view.each_pair {|k,v| attribs[camel_case(k)] = v.to_s}
      @nbuild[NS_EWS_MESSAGES].CalendarView(attribs)
    end

    # Build the ContactsView element
    def contacts_view!(con_view)
      attribs = {}
      con_view.each_pair {|k,v| attribs[camel_case(k)] = v.to_s}
      @nbuild[NS_EWS_MESSAGES].ContactsView(attribs)
    end

    # @see http://msdn.microsoft.com/en-us/library/aa579678(v=EXCHG.140).aspx
    def event_types!(evtypes)
      @nbuild[NS_EWS_TYPES].EventTypes {
        evtypes.each do |et|
          @nbuild[NS_EWS_TYPES].EventType(camel_case(et))
        end
      }
    end

    # @see http://msdn.microsoft.com/en-us/library/aa565886(v=EXCHG.140).aspx
    def watermark!(wmark, ns = NS_EWS_TYPES)
      @nbuild[ns].Watermark(wmark)
    end

    # @see http://msdn.microsoft.com/en-us/library/aa565201(v=EXCHG.140).aspx
    def timeout!(tout)
      @nbuild[NS_EWS_TYPES].Timeout(tout)
    end

    # @see http://msdn.microsoft.com/en-us/library/aa564048(v=EXCHG.140).aspx
    def status_frequency!(freq)
      @nbuild[NS_EWS_TYPES].StatusFrequency(freq)
    end

    # @see http://msdn.microsoft.com/en-us/library/aa566309(v=EXCHG.140).aspx
    def uRL!(url)
      @nbuild[NS_EWS_TYPES].URL(url)
    end

    # @see http://msdn.microsoft.com/en-us/library/aa563790(v=EXCHG.140).aspx
    def subscription_id!(subid)
      @nbuild.SubscriptionId(subid)
    end

    # @see http://msdn.microsoft.com/en-us/library/aa563455(v=EXCHG.140).aspx
    def pull_subscription_request(subopts)
      subscribe_all = subopts[:subscribe_to_all_folders] ? 'true' : 'false'
      @nbuild.PullSubscriptionRequest('SubscribeToAllFolders' => subscribe_all) {
        folder_ids!(subopts[:folder_ids]) if subopts[:folder_ids]
        event_types!(subopts[:event_types]) if subopts[:event_types]
        watermark!(subopts[:watermark]) if subopts[:watermark]
        timeout!(subopts[:timeout]) if subopts[:timeout]
      }
    end

    # @see http://msdn.microsoft.com/en-us/library/aa563599(v=EXCHG.140).aspx
    def push_subscription_request(subopts)
      subscribe_all = subopts[:subscribe_to_all_folders] ? 'true' : 'false'
      @nbuild.PushSubscriptionRequest('SubscribeToAllFolders' => subscribe_all) {
        folder_ids!(subopts[:folder_ids]) if subopts[:folder_ids]
        event_types!(subopts[:event_types]) if subopts[:event_types]
        watermark!(subopts[:watermark]) if subopts[:watermark]
        status_frequency!(subopts[:status_frequency]) if subopts[:status_frequency]
        uRL!(subopts[:uRL]) if subopts[:uRL]
      }
    end

    # @see http://msdn.microsoft.com/en-us/library/ff406182(v=EXCHG.140).aspx
    def streaming_subscription_request(subopts)
      subscribe_all = subopts[:subscribe_to_all_folders] ? 'true' : 'false'
      @nbuild.StreamingSubscriptionRequest('SubscribeToAllFolders' => subscribe_all) {
        folder_ids!(subopts[:folder_ids]) if subopts[:folder_ids]
        event_types!(subopts[:event_types]) if subopts[:event_types]
      }
    end

    # @see http://msdn.microsoft.com/en-us/library/aa565970(v=EXCHG.140).aspx
    def sync_state!(syncstate)
      @nbuild.SyncState(syncstate)
    end

    # @see http://msdn.microsoft.com/en-us/library/aa563785(v=EXCHG.140).aspx
    def ignore!(item_ids)
      @nbuild.Ignore {
        item_ids.each do |iid|
          item_id!(iid)
        end
      }
    end

    # @see http://msdn.microsoft.com/en-us/library/aa566325(v=EXCHG.140).aspx
    def max_changes_returned!(cnum)
      @nbuild[NS_EWS_MESSAGES].MaxChangesReturned(cnum)
    end

    # @see http://msdn.microsoft.com/en-us/library/dd899531(v=EXCHG.140).aspx
    def sync_scope!(scope)
      @nbuild.SyncScope(scope)
    end

    # @see http://msdn.microsoft.com/en-us/library/aa580758(v=EXCHG.140).aspx
    def saved_item_folder_id!(fid)
      @nbuild.SavedItemFolderId {
        dispatch_folder_id!(fid)
      }
    end

    # @see http://msdn.microsoft.com/en-us/library/aa565652(v=exchg.140).aspx
    def item!(item)
      nbuild.Item {
        item.each_pair {|k,v|
          self.send("#{k}!", v)
        }
      }
    end

    def message!(item)
      nbuild[NS_EWS_TYPES].Message {
        if item[:extended_properties]
          extended_properties! item.delete(:extended_properties)
        end
        item.each_pair {|k,v|
          self.send("#{k}!", v)
        }
      }
    end

    def is_read!(read)
      nbuild[NS_EWS_TYPES].IsRead(read)
    end

    def calendar_item!(item)
      nbuild[NS_EWS_TYPES].CalendarItem {
        item.each_pair {|k,v|
          self.send("#{k}!", v)
        }
      }
    end

    def calendar_item_type!(type)
      nbuild[NS_EWS_TYPES].CalendarItemType(type)
    end

    def recurrence!(item)
      nbuild[NS_EWS_TYPES].Recurrence {
        item.each_pair { |k, v|
          self.send("#{k}!", v)
        }
      }
    end

    def daily_recurrence!(item)
      nbuild[NS_EWS_TYPES].DailyRecurrence {
        item.each_pair { |k, v|
          self.send("#{k}!", v)
        }
      }
    end

    def weekly_recurrence!(item)
      nbuild[NS_EWS_TYPES].WeeklyRecurrence {
        item.each_pair { |k, v|
          self.send("#{k}!", v)
        }
      }
    end

    def interval!(num)
      nbuild[NS_EWS_TYPES].Interval(num)
    end

    def no_end_recurrence!(item)
      nbuild[NS_EWS_TYPES].NoEndRecurrence {
        item.each_pair { |k, v|
          self.send("#{k}!", v)
        }
      }
    end

    def numbered_recurrence!(item)
      nbuild[NS_EWS_TYPES].NumberedRecurrence {
        item.each_pair { |k, v|
          self.send("#{k}!", v)
        }
      }
    end

    def number_of_occurrences!(count)
      nbuild[NS_EWS_TYPES].NumberOfOccurrences(count)
    end


    def task!(item)
      nbuild[NS_EWS_TYPES].Task {
        item.each_pair {|k, v|
          self.send("#{k}!", v)
        }
      }
    end

    def forward_item!(item)
      nbuild[NS_EWS_TYPES].ForwardItem {
        item.each_pair {|k,v|
          self.send("#{k}!", v)
        }
      }
    end

    def reply_to_item!(item)
      nbuild[NS_EWS_TYPES].ReplyToItem {
        item.each_pair {|k,v|
          self.send("#{k}!", v)
        }
      }
    end

    def reply_all_to_item!(item)
      nbuild[NS_EWS_TYPES].ReplyAllToItem {
        item.each_pair {|k,v|
          self.send("#{k}!", v)
        }
      }
    end

    def reference_item_id!(id)
      nbuild[NS_EWS_TYPES].ReferenceItemId {|x|
        x.parent['Id'] = id[:id]
        x.parent['ChangeKey'] = id[:change_key] if id[:change_key]
      }
    end

    def subject!(sub)
      nbuild[NS_EWS_TYPES].Subject(sub)
    end

    def importance!(sub)
      nbuild[NS_EWS_TYPES].Importance(sub)
    end

    def body!(b)
      nbuild[NS_EWS_TYPES].Body(b[:text]) {|x|
        x.parent['BodyType'] = b[:body_type] if b[:body_type]
      }
    end

    def new_body_content!(b)
      nbuild[NS_EWS_TYPES].NewBodyContent(b[:text]) {|x|
        x.parent['BodyType'] = b[:body_type] if b[:body_type]
      }
    end

    # @see http://msdn.microsoft.com/en-us/library/aa563719(v=exchg.140).aspx
    # @param [Array] r An array of Mailbox type hashes to send to #mailbox!
    def to_recipients!(r)
      nbuild[NS_EWS_TYPES].ToRecipients {
        r.each {|mbox| mailbox!(mbox[:mailbox]) }
      }
    end

    def cc_recipients!(r)
      nbuild[NS_EWS_TYPES].CcRecipients {
        r.each {|mbox| mailbox!(mbox[:mailbox]) }
      }
    end

    def bcc_recipients!(r)
      nbuild[NS_EWS_TYPES].BccRecipients {
        r.each {|mbox| mailbox!(mbox[:mailbox]) }
      }
    end

    def from!(f)
      nbuild[NS_EWS_TYPES].From {
        mailbox! f
      }
    end

    def required_attendees!(attendees)
      nbuild[NS_EWS_TYPES].RequiredAttendees {
        attendees.each {|a| attendee!(a[:attendee])}
      }
    end

    def optional_attendees!(attendees)
      nbuild[NS_EWS_TYPES].OptionalAttendees {
        attendees.each {|a| attendee!(a[:attendee])}
      }
    end

    def resources!(attendees)
      nbuild[NS_EWS_TYPES].Resources {
        attendees.each {|a| attendee!(a[:attendee])}
      }
    end

    # @todo support ResponseType, LastResponseTime: http://msdn.microsoft.com/en-us/library/aa580339.aspx
    def attendee!(a)
      nbuild[NS_EWS_TYPES].Attendee {
        mailbox!(a[:mailbox])
      }
    end

    def start!(st)
      nbuild[NS_EWS_TYPES].Start(st[:text])
    end

    def end!(et)
      nbuild[NS_EWS_TYPES].End(et[:text])
    end

    def start_date!(sd)
      nbuild[NS_EWS_TYPES].StartDate sd[:text]
    end

    def due_date!(dd)
      nbuild[NS_EWS_TYPES].DueDate format_time(dd[:text])
    end

    def location!(loc)
      nbuild[NS_EWS_TYPES].Location(loc)
    end

    def is_all_day_event!(all_day)
      nbuild[NS_EWS_TYPES].IsAllDayEvent(all_day)
    end

    def is_response_requested!(response_requested)
      nbuild[NS_EWS_TYPES].IsResponseRequested(response_requested)
    end

    def reminder_is_set!(reminder)
      nbuild[NS_EWS_TYPES].ReminderIsSet reminder
    end

    def reminder_due_by!(date)
      nbuild[NS_EWS_TYPES].ReminderDueBy format_time(date)
    end

    def reminder_minutes_before_start!(minutes)
      nbuild[NS_EWS_TYPES].ReminderMinutesBeforeStart minutes
    end

    # @see http://msdn.microsoft.com/en-us/library/aa566143(v=exchg.150).aspx
    # possible values Exchange Server 2010 = [Free, Tentative, Busy, OOF, NoData]
    #                 Exchange Server 2013 = [Free, Tentative, Busy, OOF, WorkingElsewhere, NoData]
    def legacy_free_busy_status!(state)
      nbuild[NS_EWS_TYPES].LegacyFreeBusyStatus(state)
    end

    # @see http://msdn.microsoft.com/en-us/library/aa565428(v=exchg.140).aspx
    def item_changes!(changes)
      nbuild.ItemChanges {
        changes.each do |chg|
          item_change!(chg)
        end
      }
    end

    # @see http://msdn.microsoft.com/en-us/library/aa581081(v=exchg.140).aspx
    def item_change!(change)
      @nbuild[NS_EWS_TYPES].ItemChange {
        updates = change.delete(:updates) # Remove updates so dispatch_item_id works correctly
        dispatch_item_id!(change)
        updates!(updates)
      }
    end

    # @see http://msdn.microsoft.com/en-us/library/aa581074(v=exchg.140).aspx
    def updates!(updates)
      @nbuild[NS_EWS_TYPES].Updates {
        updates.each do |update|
          dispatch_update_type!(update)
        end
      }
    end

    # @see http://msdn.microsoft.com/en-us/library/aa581317(v=exchg.140).aspx
    def append_to_item_field!(upd)
      uri = upd.select {|k,v| k =~ /_uri/i}
      raise EwsBadArgumentError, "Bad argument given for AppendToItemField." if uri.keys.length != 1
      upd.delete(uri.keys.first)
      @nbuild.AppendToItemField {
        dispatch_field_uri!(uri)
        dispatch_field_item!(upd)
      }
    end

    # @see http://msdn.microsoft.com/en-us/library/aa581487(v=exchg.140).aspx
    def set_item_field!(upd)
      uri = upd.select {|k,v| k =~ /_uri/i}
      raise EwsBadArgumentError, "Bad argument given for SetItemField." if uri.keys.length != 1
      upd.delete(uri.keys.first)
      @nbuild[NS_EWS_TYPES].SetItemField {
        dispatch_field_uri!(uri, NS_EWS_TYPES)
        dispatch_field_item!(upd, NS_EWS_TYPES)
      }
    end

    # @see http://msdn.microsoft.com/en-us/library/aa580330(v=exchg.140).aspx
    def delete_item_field!(upd)
      uri = upd.select {|k,v| k =~ /_uri/i}
      raise EwsBadArgumentError, "Bad argument given for SetItemField." if uri.keys.length != 1
      @nbuild[NS_EWS_TYPES].DeleteItemField {
        dispatch_field_uri!(uri, NS_EWS_TYPES)
      }
    end

    # @see http://msdn.microsoft.com/en-us/library/ff709497(v=exchg.140).aspx
    def return_new_item_ids!(retval)
      @nbuild.ReturnNewItemIds(retval)
    end

    def inline_attachment!(fa)
      @nbuild[NS_EWS_TYPES].FileAttachment {
        @nbuild[NS_EWS_TYPES].Name(fa.name)
        @nbuild[NS_EWS_TYPES].ContentId(fa.name)
        @nbuild[NS_EWS_TYPES].IsInline(true)
        @nbuild[NS_EWS_TYPES].Content(fa.content)
      }
    end

    def file_attachment!(fa)
      @nbuild[NS_EWS_TYPES].FileAttachment {
        @nbuild[NS_EWS_TYPES].Name(fa.name)
        @nbuild[NS_EWS_TYPES].Content(fa.content)
      }
    end

    def item_attachment!(ia)
      @nbuild[NS_EWS_TYPES].ItemAttachment {
        @nbuild[NS_EWS_TYPES].Name(ia.name)
        @nbuild[NS_EWS_TYPES].Item {
          item_id!(ia.item)
        }
      }
    end

    # Build the AttachmentIds element
    # @see http://msdn.microsoft.com/en-us/library/aa580686.aspx
    def attachment_ids!(aids)
      @nbuild.AttachmentIds {
        @nbuild.parent.default_namespace = @default_ns
        aids.each do |aid|
          attachment_id!(aid)
        end
      }
    end

    # Build the AttachmentId element
    # @see http://msdn.microsoft.com/en-us/library/aa580764.aspx
    def attachment_id!(aid)
      attribs = {'Id' => aid}
      @nbuild[NS_EWS_TYPES].AttachmentId(attribs)
    end

    def user_configuration_name!(cfg_name)
      attribs = {'Name' => cfg_name.delete(:name)}
      @nbuild[NS_EWS_MESSAGES].UserConfigurationName(attribs) {
        fid = cfg_name.keys.first
        self.send "#{fid}!", cfg_name[fid][:id], cfg_name[fid][:change_key]
      }
    end

    def user_configuration_properties!(cfg_prop)
      @nbuild[NS_EWS_MESSAGES].UserConfigurationProperties(cfg_prop)
    end

    # ---------------------- Helpers -------------------- #

    # A helper method to dispatch to a FolderId or DistinguishedFolderId correctly
    # @param [Hash] fid A folder_id
    #   Ex: {:id => myid, :change_key => ck}
    def dispatch_folder_id!(fid)
      if(fid[:id].is_a?(String))
        folder_id!(fid[:id], fid[:change_key])
      elsif(fid[:id].is_a?(Symbol))
        distinguished_folder_id!(fid[:id], fid[:change_key], fid[:act_as])
      else
        raise EwsBadArgumentError, "Bad argument given for a FolderId. #{fid[:id].class}"
      end
    end

    # A helper method to dispatch to an ItemId, OccurrenceItemId, or a RecurringMasterItemId
    # @param [Hash] iid The item id of some type
    def dispatch_item_id!(iid)
      type = iid.keys.first
      item = iid[type]
      case type
      when :item_id
        item_id!(item)
      when :occurrence_item_id
        occurrence_item_id!(
          item[:recurring_master_id], item[:change_key], item[:instance_index])
      when :recurring_master_item_id
        recurring_master_item_id!(item[:occurrence_id], item[:change_key])
      else
        raise EwsBadArgumentError, "Bad ItemId type. #{type}"
      end
    end

    # A helper method to dispatch to a AppendToItemField, SetItemField, or
    #   DeleteItemField
    # @param [Hash] update An update of some type
    def dispatch_update_type!(update)
      type = update.keys.first
      upd  = update[type]
      case type
      when :append_to_item_field
        append_to_item_field!(upd)
      when :set_item_field
        set_item_field!(upd)
      when :delete_item_field
        delete_item_field!(upd)
      else
        raise EwsBadArgumentError, "Bad Update type. #{type}"
      end
    end

    # A helper to dispatch to a FieldURI, IndexedFieldURI, or an ExtendedFieldURI
    # @todo Implement ExtendedFieldURI
    def dispatch_field_uri!(uri, ns=NS_EWS_MESSAGES)
      type = uri.keys.first
      vals = uri[type].is_a?(Array) ? uri[type] : [uri[type]]
      case type
      when :field_uRI, :field_uri
        vals.each do |val|
          value = val.is_a?(Hash) ? val[type] : val
          nbuild[ns].FieldURI('FieldURI' => value)
        end
      when :indexed_field_uRI, :indexed_field_uri
        vals.each do |val|
          nbuild[ns].IndexedFieldURI(
            'FieldURI'   => (val[:field_uRI] || val[:field_uri]),
            'FieldIndex' => val[:field_index]
          )
        end
      when :extended_field_uRI, :extended_field_uri
        vals.each do |val|
          nbuild[ns].ExtendedFieldURI {
            nbuild.parent['DistinguishedPropertySetId'] = val[:distinguished_property_set_id] if val[:distinguished_property_set_id]
            nbuild.parent['PropertySetId'] = val[:property_set_id] if val[:property_set_id]
            nbuild.parent['PropertyTag'] = val[:property_tag] if val[:property_tag]
            nbuild.parent['PropertyName'] = val[:property_name] if val[:property_name]
            nbuild.parent['PropertyId'] = val[:property_id] if val[:property_id]
            nbuild.parent['PropertyType'] = val[:property_type] if val[:property_type]
          }
        end
      else
        raise EwsBadArgumentError, "Bad URI type. #{type}"
      end
    end

    # Insert item, enforce xmlns attribute if prefix is present
    def dispatch_field_item!(item, ns_prefix = nil)
      item.values.first[:xmlns_attribute] = ns_prefix if ns_prefix
      build_xml!(item)
    end

    def room_list!(cfg_prop)
      @nbuild[NS_EWS_MESSAGES].RoomList {
        email_address!(cfg_prop)
      }
    end

    def room_lists!
      @nbuild[NS_EWS_MESSAGES].GetRoomLists
    end

    def accept_item!(opts)
      @nbuild[NS_EWS_TYPES].AcceptItem {
        sensitivity!(opts)
        body!(opts) if opts[:text]
        reference_item_id!(opts)
      }
    end

    def tentatively_accept_item!(opts)
      @nbuild[NS_EWS_TYPES].TentativelyAcceptItem {
        sensitivity!(opts)
        body!(opts) if opts[:text]
        reference_item_id!(opts)
      }
    end

    def decline_item!(opts)
      @nbuild[NS_EWS_TYPES].DeclineItem {
        sensitivity!(opts)
        body!(opts) if opts[:text]
        reference_item_id!(opts)
      }
    end

    def sensitivity!(value)
      nbuild[NS_EWS_TYPES].Sensitivity(value[:sensitivity])
    end

private

    def parent_namespace(node)
      node.parent.namespace_definitions.find {|ns| ns.prefix == NS_SOAP}
    end

    def set_version_header!(version)
      if version && !(version == 'none')
        nbuild[NS_EWS_TYPES].RequestServerVersion {|x|
          x.parent['Version'] = version
        }
      end
    end

    def set_impersonation!(type, address)
	    if type && type != ""
	      nbuild[NS_EWS_TYPES].ExchangeImpersonation {
		      nbuild[NS_EWS_TYPES].ConnectingSID {
		        nbuild[NS_EWS_TYPES].method_missing type, address
		      }
        }
      end
	  end

    # Set TimeZoneContext Header
    # @param time_zone_def [Hash] !{id: time_zone_identifier, name: time_zone_name}
    def set_time_zone_context_header!(time_zone_def)
      if time_zone_def
        nbuild[NS_EWS_TYPES].TimeZoneContext do
          time_zone_definition! time_zone_def
        end
      end
    end

    def meeting_time_zone!(mtz)
      nbuild[NS_EWS_TYPES].MeetingTimeZone do |x|
        x.parent['TimeZoneName'] = mtz[:time_zone_name] if mtz[:time_zone_name]
        nbuild[NS_EWS_TYPES].BaseOffset(mtz[:base_offset][:text]) if mtz[:base_offset]
      end
    end

    # some methods need special naming so they use the '_r' suffix like 'and'
    def normalize_type(type)
      case type
      when :and, :or, :not
        "#{type}_r".to_sym
      else
        type
      end
    end

    def format_time(time)
      case time
      when Time, Date, DateTime
        time.to_datetime.new_offset(0).iso8601
      when String
        begin
          DateTime.parse(time).new_offset(0).iso8601
        rescue ArgumentError
          raise EwsBadArgumentError, "Invalid Time argument (#{time})"
        end
      else
        raise EwsBadArgumentError, "Invalid Time argument (#{time})"
      end
    end

  end # EwsBuilder
end # Viewpoint::EWS::SOAP
