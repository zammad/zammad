# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :template do
    name          { Faker::Name.unique.name }
    options       { {} }
    updated_by_id { 1 }
    created_by_id { 1 }

    transient do
      title { 'Title dummy.' }
      body { 'Content dummy.' }
      sender_type { 'email-out' }
      customer { create(:customer) }
      group { Group.first }
      owner { create(:agent) }
    end

    trait :dummy_data do
      options do
        {
          'formSenderType'         => sender_type,
          'title'                  => title,
          'body'                   => body,
          'customer_id'            => customer.id,
          'customer_id_completion' => "#{customer.firstname} #{customer.lastname} <#{customer.email}>",
          'group_id'               => group.id,
          'owner_id'               => owner.id,
        }
      end
    end
  end
end
