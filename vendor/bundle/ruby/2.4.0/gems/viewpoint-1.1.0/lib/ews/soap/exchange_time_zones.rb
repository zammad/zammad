module Viewpoint::EWS::SOAP

  module ExchangeTimeZones
    include Viewpoint::EWS::SOAP

    # Request list of server known time zones
    # @param full [Boolean] Request full time zone definition? Returns only name and id if false.
    # @param ids [Array] Returns only the specified time zones instead of all if present
    # @return [Array] Array of Objects responding to #id() and #name()
    # @example Retrieving server time zones
    #   ews_client = Viewpoint::EWSClient.new # ...
    #   zones = ews_client.ews.get_time_zones
    # @todo Implement TimeZoneDefinition with sub elements Periods, TransitionsGroups and Transitions
    def get_time_zones(full = false, ids = nil)
      req = build_soap! do |type, builder|
        unless type == :header
          builder.get_server_time_zones!(full: full, ids: ids)
        end
      end
      result = do_soap_request req, response_class: EwsSoapResponse

      if result.success?
        zones = []
        result.response_messages.each do |message|
          elements = message[:get_server_time_zones_response_message][:elems][:time_zone_definitions][:elems]
          elements.each do |definition|
            data = {
                id: definition[:time_zone_definition][:attribs][:id],
                name: definition[:time_zone_definition][:attribs][:name]
            }
            zones << OpenStruct.new(data)
          end
        end
        zones
      else
        raise EwsError, "Could not get time zones"
      end
    end

    # Sets the time zone context header
    # @param id [String] Identifier of a Microsoft well known time zone
    # @example Set time zone context for connection
    #   ews_client = Viewpoint::EWSClient.new # ...
    #   ews_client.set_time_zone 'AUS Central Standard Time'
    #   # subsequent request will send the TimeZoneContext header
    # @see EWSClient#set_time_zone
    def set_time_zone_context(id)
      if id
        @time_zone_context = {id: id}
      else
        @time_zone_context = nil
      end
    end

  end
end
