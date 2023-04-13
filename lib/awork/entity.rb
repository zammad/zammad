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

    ENTITY_NAME = 'entity'

    attr_reader :entity

    def initialize(client, result)
      @client = client
      @result = result
      @entity = to_h()
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
        "#{assignee['firstName']} #{assignee['lastName']}"
      end
    end

    def status
      {
        id:         @result["#{ENTITY_NAME}Status"]['id'],
        name:       @result["#{ENTITY_NAME}Status"]['name'],
        type:       @result["#{ENTITY_NAME}Status"]['type'],
        color:      status_color(@result["#{ENTITY_NAME}Status"]['type']),
      }
    end

    def status_color(type)
      STATUS_COLOR_MAP.fetch(type, 'unknown')
    end

    def image
      return if !@result['hasImage']

      client.perform('get', "files/images/#{@ENTITY_NAME}/#{@result['id']}")
    end
  end
end