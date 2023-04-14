class Awork
  class TypeOfWork < Awork::Entity

    def to_h
      {
        id:               @result['id'],
        name:             @result['name'],
        description:      @result['description']
      }
    end

  end
end