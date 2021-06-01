# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :'cti/caller_id', aliases: %i[cti_caller_id caller_id] do
    caller_id { '1234567890' }
    level     { :known }
    object    { o.class.name.to_sym }
    o_id      { o.id }
    user_id   { user.id }

    transient do
      user { User.last }
      o    { User.last }
    end
  end
end
