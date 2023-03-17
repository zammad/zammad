# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::User::Identifier < Sequencer::Unit::Common::Provider::Named

  uses :resource

  private

  def identifier
    {
      email:    primary_value('emails', 'email'),
      phone:    primary_value('phones', 'number'),
      twitter:  primary_value('twitter', 'screen_name'),
      facebook: primary_value('facebook', 'facebook_id'),
    }
  end

  def primary_value(type, field_name)
    primary_item = resource[type]&.detect { |item| item['is_primary'] }
    primary_item&.fetch(field_name)
  end
end
