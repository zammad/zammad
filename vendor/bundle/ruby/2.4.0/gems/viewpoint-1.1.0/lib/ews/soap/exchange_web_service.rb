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
  class ExchangeWebService
    include Viewpoint::EWS
    include Viewpoint::EWS::SOAP
    include Viewpoint::StringUtils
    include ExchangeDataServices
    include ExchangeNotification
    include ExchangeAvailability
    include ExchangeUserConfiguration
    include ExchangeSynchronization
    include ExchangeTimeZones

    attr_accessor :server_version, :auto_deepen, :no_auto_deepen_behavior, :connection, :impersonation_type, :impersonation_address

    # @param [Viewpoint::EWS::Connection] connection the connection object
    # @param [Hash] opts additional options to the web service
    # @option opts [String] :server_version what version to target with the
    #   requests. Must be one of the contants VERSION_2007, VERSION_2007_SP1,
    #   VERSION_2010, VERSION_2010_SP1, VERSION_2010_SP2, or VERSION_NONE. The
    #   default is VERSION_2010.
    def initialize(connection, opts = {})
      super()
      @connection = connection
      @server_version = opts[:server_version] ? opts[:server_version] : VERSION_2010
      @auto_deepen    = true
      @no_auto_deepen_behavior = :raise
      @impersonation_type = ""
      @impersonation_address = ""
    end

    def delete_attachment
      action = "#{SOAP_ACTION_PREFIX}/DeleteAttachment"
      resp = invoke("#{NS_EWS_MESSAGES}:DeleteAttachment", action) do |delete_attachment|
        build_delete_attachment!(delete_attachment)
      end
      parse_delete_attachment(resp)
    end

    def create_managed_folder
      action = "#{SOAP_ACTION_PREFIX}/CreateManagedFolder"
      resp = invoke("#{NS_EWS_MESSAGES}:CreateManagedFolder", action) do |create_managed_folder|
        build_create_managed_folder!(create_managed_folder)
      end
      parse_create_managed_folder(resp)
    end

    # Retrieves the delegate settings for a specific mailbox.
    # @see http://msdn.microsoft.com/en-us/library/bb799735.aspx
    #
    # @param [String] owner The user that is delegating permissions
    def get_delegate(owner)
      action = "#{SOAP_ACTION_PREFIX}/GetDelegate"
      resp = invoke("#{NS_EWS_MESSAGES}:GetDelegate", action) do |root|
        root.set_attr('IncludePermissions', 'true')
        build!(root) do
          mailbox!(root, {:email_address => {:text => owner}})
        end
      end
      parse_soap_response(resp)
    end

    # Adds one or more delegates to a principal's mailbox and sets specific access permissions.
    # @see http://msdn.microsoft.com/en-us/library/bb856527.aspx
    #
    # @param [String] owner The user that is delegating permissions
    # @param [String] delegate The user that is being given delegate permission
    # @param [Hash] permissions A hash of permissions that will be delegated.
    #   This Hash will eventually be passed to add_hierarchy! in the builder so it is in that format.
    def add_delegate(owner, delegate, permissions)
      action = "#{SOAP_ACTION_PREFIX}/AddDelegate"
      resp = invoke("#{NS_EWS_MESSAGES}:AddDelegate", action) do |root|
        build!(root) do
          add_delegate!(owner, delegate, permissions)
        end
      end
      parse_soap_response(resp)
    end

    # Removes one or more delegates from a user's mailbox.
    # @see http://msdn.microsoft.com/en-us/library/bb856564.aspx
    #
    # @param [String] owner The user that is delegating permissions
    # @param [String] delegate The user that is being given delegate permission
    def remove_delegate(owner, delegate)
      action = "#{SOAP_ACTION_PREFIX}/RemoveDelegate"
      resp = invoke("#{NS_EWS_MESSAGES}:RemoveDelegate", action) do |root|
        build!(root) do
          remove_delegate!(owner, delegate)
        end
      end
      parse_soap_response(resp)
    end

    # Updates delegate permissions on a principal's mailbox
    # @see http://msdn.microsoft.com/en-us/library/bb856529.aspx
    #
    # @param [String] owner The user that is delegating permissions
    # @param [String] delegate The user that is being given delegate permission
    # @param [Hash] permissions A hash of permissions that will be delegated.
    #   This Hash will eventually be passed to add_hierarchy! in the builder so it is in that format.
    def update_delegate(owner, delegate, permissions)
      action = "#{SOAP_ACTION_PREFIX}/UpdateDelegate"
      resp = invoke("#{NS_EWS_MESSAGES}:UpdateDelegate", action) do |root|
        build!(root) do
          add_delegate!(owner, delegate, permissions)
        end
      end
      parse_soap_response(resp)
    end

    # Provides detailed information about the availability of a set of users, rooms, and resources
    # within a specified time window.
    # @see http://msdn.microsoft.com/en-us/library/aa564001.aspx
    # @param [Hash] opts
    # @option opts [Hash] :time_zone The TimeZone data
    #   Example: {:bias => 'UTC offset in minutes',
    #   :standard_time => {:bias => 480, :time => '02:00:00',
    #     :day_order => 5, :month => 10, :day_of_week => 'Sunday'},
    #   :daylight_time => {same options as :standard_time}}
    # @option opts [Array<Hash>] :mailbox_data Data for the mailbox to query
    #   Example: [{:attendee_type => 'Organizer|Required|Optional|Room|Resource',
    #   :email =>{:name => 'name', :address => 'email', :routing_type => 'SMTP'},
    #   :exclude_conflicts => true|false }]
    # @option opts [Hash] :free_busy_view_options
    #   Example: {:time_window => {:start_time => DateTime,:end_time => DateTime},
    #   :merged_free_busy_interval_in_minutes => minute_int,
    #   :requested_view => None|MergedOnly|FreeBusy|FreeBusyMerged|Detailed
    #     |DetailedMerged} (optional)
    # @option opts [Hash] :suggestions_view_options (optional)
    # @todo Finish out :suggestions_view_options
    def get_user_availability(opts)
      opts = opts.clone
      req = build_soap! do |type, builder|
        if(type == :header)
        else
        builder.nbuild.GetUserAvailabilityRequest {|x|
          x.parent.default_namespace = @default_ns
          builder.time_zone!(opts[:time_zone])
          builder.nbuild.MailboxDataArray {
          opts[:mailbox_data].each do |mbd|
            builder.mailbox_data!(mbd)
          end
          }
          builder.free_busy_view_options!(opts[:free_busy_view_options])
          builder.suggestions_view_options!(opts[:suggestions_view_options])
        }
        end
      end

      do_soap_request(req, response_class: EwsSoapFreeBusyResponse)
    end

    # Gets the rooms that are in the specified room distribution list
    # @see http://msdn.microsoft.com/en-us/library/aa563465.aspx
    # @param [string] roomDistributionList
    def get_rooms(roomDistributionList)
      req = build_soap! do |type, builder|
        if(type == :header)
        else
          builder.nbuild.GetRooms {|x|
            x.parent.default_namespace = @default_ns
            builder.room_list!(roomDistributionList)
          }
        end
      end
      do_soap_request(req, response_class: EwsSoapRoomResponse)
    end

    # Gets the room lists that are available within the Exchange organization.
    # @see http://msdn.microsoft.com/en-us/library/aa563465.aspx
    def get_room_lists
      req = build_soap! do |type, builder|
        if(type == :header)
        else
          builder.room_lists!
        end
      end
      do_soap_request(req, response_class: EwsSoapRoomlistResponse)
    end

    # Send the SOAP request to the endpoint and parse it.
    # @param [String] soapmsg an XML formatted string
    # @todo make this work for Viewpoint (imported from SPWS)
    # @param [Hash] opts misc options
    # @option opts [Boolean] :raw_response if true do not parse and return
    #   the raw response string.
    def do_soap_request(soapmsg, opts = {})
      @log.debug <<-EOF.gsub(/^ {8}/, '')
        Sending SOAP Request:
        ----------------
        #{soapmsg}
        ----------------
      EOF
      connection.dispatch(self, soapmsg, opts)
    end

    # @param [String] response the SOAP response string
    # @param [Hash] opts misc options to send to the parser
    # @option opts [Class] :response_class the response class
    def parse_soap_response(soapmsg, opts = {})
      raise EwsError, "Can't parse an empty response. Please check your endpoint." if(soapmsg.nil?)
      opts[:response_class] ||= EwsSoapResponse
      EwsParser.new(soapmsg).parse(opts)
    end


    private
    # Private Methods (Builders and Parsers)

    # Validate or set default values for options parameters.
    # @param [Hash] opts The options parameter passed to an EWS operation
    # @param [Symbol] key The key in the Hash we are validating
    # @param [Boolean] required Whether or not this key is required
    # @param [Object] default_val If the key is not required use this as a
    #   default value for the operation.
    def validate_param(opts, key, required, default_val = nil)
      if required
        raise EwsBadArgumentError, "Required parameter(#{key}) not passed." unless opts.has_key?(key)
        opts[key]
      else
        raise EwsBadArgumentError, "Default value not supplied." unless default_val
        opts.has_key?(key) ? opts[key] : default_val
      end
    end

    # Some operations only exist for certain versions of Exchange Server.
    # This method should be called with the required version and we'll throw
    # an exception of the currently set @server_version does not comply.
    def validate_version(exchange_version)
      if server_version < exchange_version
        msg = 'The operation you are attempting to use is not compatible with'
        msg << " your configured Exchange Server version(#{server_version})."
        msg << " You must be running at least version (#{exchange_version})."
        raise EwsServerVersionError, msg
      end
    end

    # Build the common elements in the SOAP message and yield to any custom elements.
    def build_soap!(&block)
      opts = { :server_version => server_version, :impersonation_type => impersonation_type, :impersonation_mail => impersonation_address }
      opts[:time_zone_context] = @time_zone_context if @time_zone_context
      EwsBuilder.new.build!(opts, &block)
    end

  end # class ExchangeWebService
end # Viewpoint
