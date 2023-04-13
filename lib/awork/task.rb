class Awork
  class Task < Awork::Entity

    ENTITY_NAME = 'task'

    def to_h
      {
        id:               @result['id'],
        title:            @result['title'],
        description:      @result['description'],
        assignees:        assignees,
        tags:             tags,
        status:           status,
      }
    end

    private

    def tags
      @result['tags'].map do |tag|
        {
          id:     tag['id'],
          color:  tag['color'],
          name:   tag['name']
        }
      end
    end
  end
end