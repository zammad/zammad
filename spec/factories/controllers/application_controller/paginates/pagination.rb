# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :'can_paginate/pagination', aliases: %i[pagination] do

    params  { {} }
    default { nil }
    max { nil }

    initialize_with { new(params, default: default, max: max) }
  end
end
