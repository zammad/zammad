# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::System::SetSystemInformation < Service::Base
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
  attr_reader :new_setting_data

  def initialize(data:)
    super()

    @new_settings = parse_data(data)
  end

  def execute
    update_settings
  end

  private

  def parse_data(kwargs)
    params = {}

    if !Setting.get('system_online_service')
      begin
        url_information = UrlInformation.new(kwargs[:url])

        params[:http_type] = url_information.scheme
        params[:fqdn]      = url_information.fqdn
      rescue
        raise Exceptions::InvalidAttribute.new('url', __('Please include a valid url.'))
      end
    end

    raise Exceptions::MissingAttribute.new('organizaton', __("The required attribute 'organization' is missing.")) if kwargs[:organization].blank?

    params[:organization] = kwargs[:organization]

    params[:locale_default]   = kwargs[:locale_default]   if kwargs[:locale_default].present?
    params[:timezone_default] = kwargs[:timezone_default] if kwargs[:timezone_default].present?

    if (logo_timestamp = Service::SystemAssets::ProductLogo.store(kwargs[:logo], kwargs[:logo_resize]))
      params[:product_logo] = logo_timestamp
    end

    params
  end

  def update_settings
    @new_settings.each do |key, value|
      Setting.set(key, value)
    end
  end
end
