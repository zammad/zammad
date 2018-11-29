require 'uri'

class RedirectUriValidator < ActiveModel::EachValidator
  def self.native_redirect_uri
    Doorkeeper.configuration.native_redirect_uri
  end

  def validate_each(record, attribute, value)
    if value.blank?
      record.errors.add(attribute, :blank)
    else
      value.split.each do |val|
        uri = ::URI.parse(val)
        return if native_redirect_uri?(uri)
        record.errors.add(attribute, :fragment_present) unless uri.fragment.nil?
        record.errors.add(attribute, :relative_uri) if uri.scheme.nil? || uri.host.nil?
        record.errors.add(attribute, :secured_uri) if invalid_ssl_uri?(uri)
      end
    end
  rescue URI::InvalidURIError
    record.errors.add(attribute, :invalid_uri)
  end

  private

  def native_redirect_uri?(uri)
    self.class.native_redirect_uri.present? && uri.to_s == self.class.native_redirect_uri.to_s
  end

  def invalid_ssl_uri?(uri)
    forces_ssl = Doorkeeper.configuration.force_ssl_in_redirect_uri
    forces_ssl && uri.try(:scheme) == 'http'
  end
end
