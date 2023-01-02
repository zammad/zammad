# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::User::ImageSource < Sequencer::Unit::Common::Provider::Named

  uses :resource

  private

  def image_source
    resource&.photo&.content_url
  end
end
