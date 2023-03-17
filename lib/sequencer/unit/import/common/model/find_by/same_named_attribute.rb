# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::Model::FindBy::SameNamedAttribute < Sequencer::Unit::Import::Common::Model::Lookup::Attributes

  private

  def attribute
    self.class.name.demodulize.underscore.to_sym
  end
end
