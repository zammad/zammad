# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :'user/overview_sorting' do
    overview        { create(:overview) }
    created_by_id   { 1 }
    updated_by_id   { 1 }
  end
end
