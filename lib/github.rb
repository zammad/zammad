# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class GitHub < GitIntegrationBase
  def initialize(endpoint:, api_token:)
    super()

    @client     = GitHub::HttpClient.new(endpoint, api_token)
    @issue_type = :github
  end

  def verify!
    GitHub::Credentials.new(client).verify!
  end

  def issues_by_urls(urls)
    url_replacements = {}
    issues = urls.uniq.each_with_object([]) do |url, result|
      issue = issue_by_url(url)
      next if issue.blank?

      if issue[:url] != url
        url_replacements.store(url, issue[:url])
      end

      result << issue
    end

    {
      issues:           issues,
      url_replacements: url_replacements
    }
  end

  def issue_by_url(url)
    issue = GitHub::LinkedIssue.new(client)
    issue.find_by(url)&.to_h
  end
end
