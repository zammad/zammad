# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Common::ArticleSourceChannel < Sequencer::Unit::Common::Provider::Named

  uses :resource, :id_map

  private

  def article_source_channel
    channel = resource['source_channel']&.fetch('type')

    return if !channel

    "Sequencer::Unit::Import::Kayako::Post::Channel::#{channel.capitalize}".constantize.new(resource)
  end
end
