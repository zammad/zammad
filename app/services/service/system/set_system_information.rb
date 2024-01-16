# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::System::SetSystemInformation < Service::Base
  Result = Struct.new(:updated_settings, :errors, keyword_init: true) do
    def success?
      errors.blank?
    end
  end

  # Setup basic system settigns
  #
  # @param [Hash] input basic settings
  # @option input [String] :url system URL to work out http type and FQDN from
  # @option input [String] :organization aka organization name
  # @option input [String] :locale_default optional locale name
  # @option input [String] :timezone_default optional timezone
  # @option input [String] :logo binary string of an image
  # @option input [String] :logo_resize binary string of an image
  #
  def execute(input)
    params, errors = parse_arguments(input)

    update_settings(params) if errors.blank?

    Result.new(updated_settings: params, errors: errors)
  end

  private

  def parse_arguments(kwargs)
    params = {}
    errors = []

    if !Setting.get('system_online_service')
      if (result = UriHelper.validate_uri(kwargs[:url]))
        params[:http_type] = result[:scheme]
        params[:fqdn]      = result[:fqdn]
      else
        errors << { message: __('should look like this: https://zammad.example.com'), field: :url }
      end
    end

    if kwargs[:organization].present?
      params[:organization] = kwargs[:organization]
    else
      errors << { message: __('is required'), field: :organization }
    end

    if errors.blank?
      params[:locale_default]   = kwargs[:locale_default]   if kwargs[:locale_default].present?
      params[:timezone_default] = kwargs[:timezone_default] if kwargs[:timezone_default].present?

      if (logo_timestamp = Service::SystemAssets::ProductLogo.store(kwargs[:logo], kwargs[:logo_resize]))
        params[:product_logo] = logo_timestamp
      end
    end

    [params, errors]
  end

  def update_settings(params)
    params.each do |key, value|
      Setting.set(key, value)
    end
  end
end
