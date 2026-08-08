# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::System::Import::ApplyJiraConfiguration < Service::System::Import::ApplyConfigurationBase

  attr_reader :project_key

  def initialize(url:, secret: nil, username: nil, tls_verify: true, project_key: nil)
    super(url:, secret:, username:, tls_verify:)

    @project_key = project_key
  end

  def execute
    super

    Setting.set('import_jira_endpoint', @endpoint)
    Setting.set('import_jira_email', @username)
    Setting.set('import_jira_api_token', @secret)
    Setting.set('import_jira_project_key', @project_key)
    Setting.set('import_backend', 'jira')
  end

  private

  def build_endpoint
    @url.to_s.chomp('/')
  end

  def reachable!
    response = request("#{@endpoint}/rest/api/3/serverInfo", verify_ssl: @tls_verify)
    return if response.success?

    message = response.error.to_s.presence || __('The hostname could not be found.')
    raise_unreachable_error(message)
  end

  def accessible!
    result = check_accessibility { Sequencer.process('Import::Jira::ConnectionTest') }
    raise InaccessibleError, __('The provided credentials are invalid.') if !result[:connected]

    result = check_accessibility { Sequencer.process('Import::Jira::PermissionCheck') }
    raise InaccessibleError, __('The account cannot browse the given Jira project.') if !result[:permission_present]
  end

  def check_accessibility(&)
    apply_settings
    result = yield
    clear_settings

    result
  end

  def apply_settings
    Setting.set('import_jira_endpoint', @endpoint)
    Setting.set('import_jira_email', @username)
    Setting.set('import_jira_api_token', @secret)
    Setting.set('import_jira_project_key', @project_key)
  end

  def clear_settings
    Setting.set('import_jira_endpoint', nil)
    Setting.set('import_jira_email', nil)
    Setting.set('import_jira_api_token', nil)
    Setting.set('import_jira_project_key', nil)
  end

  def raise_unreachable_error(message)
    messages = {
      'No such file'                                              => __('The hostname could not be found.'),
      'getaddrinfo: nodename nor servname provided, or not known' => __('The hostname could not be found.'),
      '503 Service Temporarily Unavailable'                       => __('The hostname could not be found.'),
      'No route to host'                                          => __('There is no route to this host.'),
      'Connection refused'                                        => __('The connection was refused.'),
    }

    human_message = messages.find { |key, _| message.match?(%r{#{Regexp.escape(key)}}i) }&.last

    raise UnreachableError, human_message.presence || message
  end
end
