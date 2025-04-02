# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :'user/overview_sorting', aliases: %w[user_overview_sorting] do
    overview
    created_by_id   { 1 }
    updated_by_id   { 1 }
  end
end
