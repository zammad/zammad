# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class RobotsTxtController < ApplicationController

  helper_method :custom_address_uri, :custom_path?, :custom_domain_path?

  def index
    render layout: false, content_type: 'text/plain'
  end

  private

  def knowledge_base
    @knowledge_base ||= KnowledgeBase.active.first
  end

  def custom_address_uri
    @custom_address_uri ||= knowledge_base&.custom_address_uri
  end

  def custom_address_host
    custom_address_uri&.host
  end

  def custom_path?
    custom_address_uri && custom_address_host.blank?
  end

  def custom_domain_path?
    return false if custom_address_uri.blank?

    given_fqdn = request.headers.env['SERVER_NAME']&.downcase
    kb_fqdn    = custom_address_host&.downcase

    given_fqdn == kb_fqdn
  end
end
