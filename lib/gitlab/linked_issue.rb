# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class GitLab
  class LinkedIssue

    STATES_MAPPING = {
      'opened' => 'open'
    }.freeze

    FETCH_INITIAL_ISSUE_QUERY = <<-GRAPHQL.freeze
      query($fullpath: ID!, $issue_id: String) {
        project(fullPath: $fullpath) {
          issue(iid: $issue_id) {
            id
            iid
            webUrl
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

    FETCH_ISSUE_QUERY = <<-GRAPHQL.freeze
      query($issue_id: IssueID!) {
        issue(id: $issue_id) {
          id
          iid
          webUrl
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
    GRAPHQL

    attr_reader :client

    def initialize(client)
      @client = client
    end

    def find_issue_by_url(url)
      @result = query_issue_by_url(url)
      return if @result.blank?

      to_h
    end

    def get_issue(gid)
      @result = query_issue_by_gid(gid)
      return if @result.blank?

      to_h
    end

    private

    def to_h
      {
        gid:        @result['id'],
        id:         @result['iid'],
        title:      @result['title'],
        url:        @result['webUrl'],
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

    def query_issue_by_url(url)
      variables = variables(url)
      return if variables.blank?

      response = client.perform(
        query:     GitLab::LinkedIssue::FETCH_INITIAL_ISSUE_QUERY,
        variables: variables
      )

      response.dig('data', 'project', 'issue')
    end

    def query_issue_by_gid(gid)
      return if gid.nil?

      response = client.perform(
        query:     GitLab::LinkedIssue::FETCH_ISSUE_QUERY,
        variables: {
          issue_id: gid
        }
      )

      response.dig('data', 'issue')
    end

    def variables(url)
      if url !~ %r{^https?://([^/]+)/(.*)/-/issues/(\d+)$}
        raise Exceptions::UnprocessableEntity, __('Invalid GitLab issue link format')
      end

      host     = $1
      fullpath = $2
      id       = $3

      if client.endpoint_path.present?
        fullpath.sub!(client.endpoint_path, '')
      end

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
