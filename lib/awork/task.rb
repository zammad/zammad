class Awork
  class Task < Awork::Entity

    entity_name='task'

    def to_h
      {
        id:               @result['iid'],
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