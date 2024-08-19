# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class GitLab
  class LinkedIssue

    STATES_MAPPING = {
      'opened' => 'open'
    }.freeze

    QUERY = <<-GRAPHQL.freeze
      query($fullpath: ID!, $issue_id: String) {
        project(fullPath: $fullpath) {
          issue(iid: $issue_id) {
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

    attr_reader :client

    def initialize(client)
      @client = client
    end

    def find_by(url)
      @result = query_by_url(url)

      if @result.blank?
        new_url = query_new_url_by_rest_api(url)
        return if new_url.blank?

        @result = query_by_url(new_url)
      end

      return if @result.blank?

      to_h
    end

    private

    def to_h
      {
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

    def query_by_url(url)
      variables = variables(url)
      return if variables.blank?

      response = client.perform(
        query:     GitLab::LinkedIssue::QUERY,
        variables: variables
      )

      response.dig('data', 'project', 'issue')
    end

    def query_new_url_by_rest_api(url)
      variables = variables(url)
      return if variables.blank?

      response = client.perform_rest_get_request(variables)
      return if response.blank?

      response['web_url']
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
