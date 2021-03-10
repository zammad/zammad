# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class GitLab
  extend Forwardable

  attr_reader :client

  def_delegator :client, :schema

  def initialize(*args, **kargs)
    @client = GitLab::Client.new(*args, **kargs)
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
