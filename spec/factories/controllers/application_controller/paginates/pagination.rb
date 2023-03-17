# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :'can_paginate/pagination', aliases: %i[pagination] do

    params  { {} }
    default { nil }
    max { nil }

    initialize_with { new(params, default:, max:) }
  end
end
