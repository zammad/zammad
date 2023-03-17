# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::Model::FindBy::UserAttributes < Sequencer::Unit::Import::Common::Model::Lookup::Attributes

  private

  def attributes
    %i[login email]
  end
end
