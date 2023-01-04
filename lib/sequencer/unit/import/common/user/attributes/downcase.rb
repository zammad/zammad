# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::User::Attributes::Downcase < Sequencer::Unit::Base
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  skip_action :skipped, :failed

  uses :mapped

  def process
    %i[login email].each do |attribute|
      next if mapped[attribute].blank?

      mapped[attribute].downcase!
    end
  end
end
