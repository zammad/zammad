class Awork
  class Project < Awork::Entity

    entity_name='project'

    def to_h
      {
        id:               @result['id'],
        name:             @result['name'],
        description:      @result['description'],
        status:           status,
        image:            image
      }
    end

  end
end