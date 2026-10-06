# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class MicrosoftCloud
  ENDPOINTS = {
    'global' => {
      login_host:       'login.microsoftonline.com',
      graph_host:       'graph.microsoft.com',
      imap_host:        'outlook.office365.com',
      smtp_host:        'smtp.office365.com',
      outlook_resource: 'https://outlook.office.com',
    },
    'us_gov' => {
      login_host:       'login.microsoftonline.us',
      graph_host:       'graph.microsoft.us',
      imap_host:        'outlook.office365.us',
      smtp_host:        'outlook.office365.us',
      outlook_resource: 'https://outlook.office365.us',
    },
  }.freeze

  attr_reader :name

  def initialize(name = nil)
    @name = name.to_s.empty? ? 'global' : name.to_s
    @endpoints = ENDPOINTS.fetch(@name) { raise ArgumentError, __('Unknown Microsoft cloud.') }
  end

  def login_host
    @endpoints[:login_host]
  end

  def graph_host
    @endpoints[:graph_host]
  end

  def graph_base_url
    "https://#{graph_host}/v1.0/"
  end

  def imap_host
    @endpoints[:imap_host]
  end

  def smtp_host
    @endpoints[:smtp_host]
  end

  def outlook_resource
    @endpoints[:outlook_resource]
  end

  def graph_scope(permission)
    name == 'global' ? permission : "https://#{graph_host}/#{permission}"
  end
end
