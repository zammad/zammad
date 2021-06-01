# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class GitHub
  class LinkedIssue

    STATES_MAPPING = {
      'OPEN'   => 'open',
      'CLOSED' => 'closed'
    }.freeze

    QUERY = <<-'GRAPHQL'.freeze
      query($repositor_owner: String!, $repository_name: String!, $issue_id: Int!) {
       repository(owner: $repositor_owner, name: $repository_name) {
         issue(number: $issue_id) {
           number
           title
           state
           milestone {
             title
           }
           assignees(last: 100) {
             edges {
               node {
                 name
               }
             }
           }
           labels(last: 100) {
             edges {
               node {
                 name
                 color
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
        id:         @result['number'].to_s,
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
          text_color: text_color(label['node']['color']),
          color:      "##{label['node']['color']}",
          title:      label['node']['name']
        }
      end
    end

    def text_color(background_color)
      background_color.to_i(16) > 0xFFF / 2 ? '#000000' : '#FFFFFF'
    end

    def milestone
      @result.dig('milestone', 'title')
    end

    def query_by_url(url)
      response = client.perform(
        query:     GitHub::LinkedIssue::QUERY,
        variables: variables!(url)
      )

      response.dig('data', 'repository', 'issue')
    end

    def variables!(url)
      if url !~ %r{^https?://([^/]+)/([^/]+)/([^/]+)/issues/(\d+)$}
        raise Exceptions::UnprocessableEntity, 'Invalid GitHub issue link format'
      end

      host            = $1
      repositor_owner = $2
      repository_name = $3
      id              = $4

      if client.endpoint.exclude?(host)
        raise Exceptions::UnprocessableEntity, "Issue link doesn't match configured GitHub endpoint '#{client.endpoint}'"
      end

      {
        repositor_owner: repositor_owner,
        repository_name: repository_name,
        issue_id:        id.to_i,
      }
    end
  end
end
