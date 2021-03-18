# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
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

    def query
      @query ||= client.parse GitHub::LinkedIssue::QUERY
    end

    def query_by_url(url)
      variables = variables(url)
      return if variables.blank?

      response = client.query(query, variables: variables)

      response&.data&.repository&.issue&.to_h&.deep_dup
    end

    def variables(url)
      return if url !~ %r{^https://([^/]+)/([^/]+)/([^/]+)/issues/(\d+)$}

      host            = $1
      repositor_owner = $2
      repository_name = $3
      id              = $4

      return if client.endpoint.exclude?(host)

      {
        repositor_owner: repositor_owner,
        repository_name: repository_name,
        issue_id:        id.to_i,
      }
    end
  end
end
