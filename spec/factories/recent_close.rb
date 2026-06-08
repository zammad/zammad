# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :recent_close do
    recently_closed_object { association(:ticket) }
    user                   { association(:agent) }
  end
end
