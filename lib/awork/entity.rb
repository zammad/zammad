class Awork
  class Entity

    STATUS_COLOR_MAP = {
      'not-started' => '#5bc0ff',
      'progress' => '#ffd26a',
      'in_release' => '#c17fff',
      'stuck' => '#ff4398',
      'closed' => '#33f29e',
      'unknown' => '#000000',
    }.freeze

    attr_reader :entity

    def initialize(client, result)
      @client = client
      @result = result
      @entity = to_h()
    end

    def to_h
      {
        id:               @result['id'],
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
        "#{assignee['firstName']} #{assignee['lastName']}"
      end
    end

    def status(entity_name = 'entity')
      {
        id:         @result["#{entity_name}Status"]['id'],
        name:       @result["#{entity_name}Status"]['name'],
        type:       @result["#{entity_name}Status"]['type'],
        color:      status_color(@result["#{entity_name}Status"]['type']),
      }
    end

    def status_color(type)
      puts type
      STATUS_COLOR_MAP.fetch(type, 'unknown')
    end
  end
end