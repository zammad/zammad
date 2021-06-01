# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :object_lookup do
    name { (ApplicationModel.descendants.map(&:name) - ObjectLookup.pluck(:name)).sample }
  end
end
