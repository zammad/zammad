# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class GitLab
  class LinkedIssue

    STATES_MAPPING = {
      'opened' => 'open'
    }.freeze

    QUERY = <<-'GRAPHQL'.freeze
      query($fullpath: ID!, $issue_id: String) {
        project(fullPath: $fullpath) {
          issue(iid: $issue_id) {
            iid
            title
            state
            milestone {
              title
            }
            assignees {
              edges {
                node {
                  name
                }
              }
            }
            labels {
              edges {
                node {
                  title
                  color
                  textColor
                  description
                }
              }
            }
          }
        }
      }
    GRAPHQL

    attr_reader :client

    def initialize(client)
      @client = client
    end

    def find_by(url)
      @result = query_by_url(url)
      return if @result.blank?

      to_h.merge(url: url)
    end

    private

    def to_h
      {
        id:         @result['iid'],
        title:      @result['title'],
        icon_state: STATES_MAPPING.fetch(@result['state'], @result['state']),
        milestone:  milestone,
        assignees:  assignees,
        labels:     labels,
      }
    end

    def assignees
      @result['assignees']['edges'].map do |assignee|
        assignee['node']['name']
      end
    end

    def labels
      @result['labels']['edges'].map do |label|
        {
          text_color: label['node']['textColor'],
          color:      label['node']['color'],
          title:      label['node']['title']
        }
      end
    end

    def milestone
      @result.dig('milestone', 'title')
    end

    def query_by_url(url)
      variables = variables(url)
      return if variables.blank?

      response = client.perform(
        query:     GitLab::LinkedIssue::QUERY,
        variables: variables
      )

      response.dig('data', 'project', 'issue')
    end

    def variables(url)
      if url !~ %r{^https?://([^/]+)/(.*)/-/issues/(\d+)$}
        raise Exceptions::UnprocessableEntity, 'Invalid GitLab issue link format'
      end

      host     = $1
      fullpath = $2
      id       = $3

      if client.endpoint.exclude?(host)
        raise Exceptions::UnprocessableEntity, "Issue link doesn't match configured GitLab endpoint '#{client.endpoint}'"
      end

      {
        fullpath: fullpath,
        issue_id: id
      }
    end
  end
end
