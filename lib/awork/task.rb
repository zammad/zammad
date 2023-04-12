class Awork
  class Task < Awork::Entity

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
          id:         tag['node']['id'],
          color:      tag['node']['color'],
          title:      tag['node']['title']
        }
      end
    end
  end
end