module Viewpoint::EWS::SOAP

  # Exchange Availability operations as listed in the EWS Documentation.
  # @see http://msdn.microsoft.com/en-us/library/bb409286.aspx
  module ExchangeAvailability
    include Viewpoint::EWS::SOAP

    # -------------- Availability Operations -------------

    # Gets a mailbox user's Out of Office (OOF) settings and messages.
    # @see http://msdn.microsoft.com/en-us/library/aa563465.aspx
    # @param [Hash] opts
    # @option opts [String] :address the email address of the user
    # @option opts [String] :name the user display name (optional)
    # @option opts [String] :routing_type the routing protocol (optional and stupid)
    def get_user_oof_settings(opts)
      opts = opts.clone
      [:address].each do |k|
        validate_param(opts, k, true)
      end
      req = build_soap! do |type, builder|
        if(type == :header)
        else
        builder.nbuild.GetUserOofSettingsRequest {|x|
          x.parent.default_namespace = @default_ns
          builder.mailbox!(opts)
        }
        end
      end
      do_soap_request(req, response_class: EwsSoapAvailabilityResponse)
    end

    # Sets a mailbox user's Out of Office (OOF) settings and message.
    # @see http://msdn.microsoft.com/en-us/library/aa580294.aspx
    # @param [Hash] opts
    # @option opts [Hash] :mailbox the mailbox hash for the use
    # @option opts [String,Symbol] :oof_state :enabled, :disabled, :scheduled
    # @option opts [Hash] :duration {start_time: DateTime, end_time: DateTime}
    # @option opts [String] :internal_reply
    # @option opts [String] :external_reply
    # @option opts [String,Symbol] :external_audience :none, :known, :all
    def set_user_oof_settings(opts)
      opts = opts.clone
      [:mailbox, :oof_state].each do |k|
        validate_param(opts, k, true)
      end
      req = build_soap! do |type, builder|
        if(type == :header)
        else
        builder.nbuild.SetUserOofSettingsRequest {|x|
          x.parent.default_namespace = @default_ns
          builder.mailbox! opts.delete(:mailbox)
          builder.user_oof_settings!(opts)
        }
        end
      end
      do_soap_request(req, response_class: EwsSoapAvailabilityResponse)
    end

  end #ExchangeAvailability
end
