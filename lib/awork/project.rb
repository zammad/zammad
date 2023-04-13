class Awork
  class Project < Awork::Entity

    def to_h
      {
        id:               @result['id'],
        name:             @result['name'],
        description:      @result['description'],
        status:           status('project')
      }
    end

  end
end