class Awork
  class Entity

    STATUS_COLOR_MAP = {
      'open':         '#5bc0ff',
      'progress':     '#ffd26a',
      'in_release':   '#c17fff',
      'blocked':      '#ff4398',
      'done':         '#33f29e',
      'unknown':      '#000000',
    }.freeze

    entity_name = 'entity'

    attr_reader :client, :result

    def initialize(client, result)
      @client = client
      @result = result
    end

    def to_h
      {
        id:               @result['iid'],
        title:            @result['title'],
        description:      @result['description'],
        status:           status,
        assignees:        assignees,
        image:            image
      }
    end

    private

    def assignees
      @result['assignees'].map do |assignee|
        "#{ assignee['firstName'] } #{ assignee['lastName'] }"
      end
    end

    def status
      {
        id:         @result["#{ entity_name }Status"]['id'],
        name:       @result["#{ entity_name }Status"]['name'],
        type:       @result["#{ entity_name }Status"]['type'],
        color:      status_color(@result["#{ entity_name }Status"]['type']),
      }
    end

    def status_color(type)
      STATUS_COLOR_MAP.fetch(type, 'unknown')
    end

    def image
      return if !@result['hasImage']

      client.perform('get', "files/images/#{ @entity_name }/#{ @result['id'] }")
    end
  end
end