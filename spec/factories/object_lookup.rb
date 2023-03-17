# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :object_lookup do
    name { (ApplicationModel.descendants.map(&:name) - ObjectLookup.pluck(:name)).sample }
  end
end
