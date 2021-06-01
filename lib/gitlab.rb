# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class GitLab
  attr_reader :client

  def initialize(endpoint, api_token)
    @client = GitLab::HttpClient.new(endpoint, api_token)
  end

  def verify!
    GitLab::Credentials.new(client).verify!
  end

  def issues_by_urls(urls)
    urls.uniq.each_with_object([]) do |url, result|
      issue = issue_by_url(url)
      next if issue.blank?

      result << issue
    end
  end

  def issue_by_url(url)
    issue = GitLab::LinkedIssue.new(client)
    issue.find_by(url)&.to_h
  end
end
