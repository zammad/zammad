# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Ticket::Comment::SourceBased < Sequencer::Unit::Common::Provider::Named

  uses :resource

  def value
    return if private_methods(false).exclude?(value_method_name)

    send(value_method_name)
  end

  def value_method_name
    @value_method_name ||= resource.via.channel.to_sym
  end
end
