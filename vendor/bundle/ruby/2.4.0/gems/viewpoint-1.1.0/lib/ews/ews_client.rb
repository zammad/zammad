require 'ews/folder_accessors'
require 'ews/item_accessors'
require 'ews/message_accessors'
require 'ews/mailbox_accessors'
require 'ews/push_subscription_accessors'
require 'ews/calendar_accessors'
require 'ews/room_accessors'
require 'ews/roomlist_accessors'
require 'ews/convert_accessors'
require 'ews/meeting_accessors'

# This class is the glue between the Models and the Web Service.
class Viewpoint::EWSClient
  include Viewpoint::EWS
  include Viewpoint::EWS::FolderAccessors
  include Viewpoint::EWS::ItemAccessors
  include Viewpoint::EWS::MessageAccessors
  include Viewpoint::EWS::MailboxAccessors
  include Viewpoint::EWS::PushSubscriptionAccessors
  include Viewpoint::EWS::CalendarAccessors
  include Viewpoint::EWS::RoomAccessors
  include Viewpoint::EWS::RoomlistAccessors
  include Viewpoint::EWS::ConvertAccessors
  include Viewpoint::EWS::MeetingAccessors
  include Viewpoint::StringUtils

  # The instance of Viewpoint::EWS::SOAP::ExchangeWebService
  attr_reader :ews, :endpoint, :username

  # Initialize the EWSClient instance.
  # @param [String] endpoint The EWS endpoint we will be connecting to
  # @param [String] user The user to authenticate as. If you are using
  #   NTLM or Negotiate authentication you do not need to pass this parameter.
  # @param [String] pass The user password. If you are using NTLM or
  #   Negotiate authentication you do not need to pass this parameter.
  # @param [Hash] opts Various options to pass to the backends
  # @option opts [String] :server_version The Exchange server version to
  #   target. See the VERSION_* constants in
  #   Viewpoint::EWS::SOAP::ExchangeWebService.
  # @option opts [Object] :http_class specify an alternate HTTP connection class.
  # @option opts [Hash] :http_opts options to pass to the connection
  def initialize(endpoint, username, password, opts = {})
    # dup all. @see ticket https://github.com/zenchild/Viewpoint/issues/68
    @endpoint = endpoint.dup
    @username = username.dup
    password  = password.dup
    opts      = opts.dup
    http_klass = opts[:http_class] || Viewpoint::EWS::Connection
    con = http_klass.new(endpoint, opts[:http_opts] || {})
    con.set_auth @username, password
    @ews = SOAP::ExchangeWebService.new(con, opts)
  end

  # @param deepen [Boolean] true to autodeepen, false otherwise
  # @param behavior [Symbol] :raise, :nil When setting autodeepen to false you
  #   can choose what the behavior is when an attribute does not exist. The
  #   default is to raise a EwsMinimalObjectError.
  def set_auto_deepen(deepen, behavior = :raise)
    if deepen
      ews.auto_deepen = true
    else
      behavior = [:raise, :nil].include?(behavior) ? behavior : :raise
      ews.no_auto_deepen_behavior = behavior
      ews.auto_deepen = false
    end
  end

  def auto_deepen=(deepen)
    set_auto_deepen deepen
  end

  # Specify a default time zone context for all time attributes
  # @param id [String] Identifier of a Microsoft well known time zone (e.g: 'UTC', 'W. Europe Standard Time')
  # @note A list of time zones known by the server can be requested via {EWS::SOAP::ExchangeTimeZones#get_time_zones}
  def set_time_zone(microsoft_time_zone_id)
    ews.set_time_zone_context microsoft_time_zone_id
  end

  private


  # This method also exists in EWS::Types, but there is a lot of other stuff
  # in there that I didn't want to include directly in this class.
  def class_by_name(cname)
    if(cname.instance_of? Symbol)
      cname = camel_case(cname)
    end
    Viewpoint::EWS::Types.const_get(cname)
  end

  # Used for multiple accessors
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

end
