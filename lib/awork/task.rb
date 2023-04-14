class Awork
  class Task < Awork::Entity

    def to_h
      {
        id:               @result['id'],
        url:              "https://tomato-word-class-fairies.awork.io/tasks/#{@result['id']}/details",
        name:             @result['name'],
        description:      @result['description'],
        assignees:        assignees,
        tags:             tags,
        status:           status('task'),
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