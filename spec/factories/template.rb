# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :template do
    name          { Faker::Name.unique.name }
    options       { { 'ticket.title': 'Some dummy title' } }
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
          'ticket.formSenderType'         => sender_type,
          'ticket.title'                  => title,
          'article.body'                  => body,
          'ticket.customer_id'            => customer.id,
          'ticket.customer_id_completion' => "#{customer.firstname} #{customer.lastname} <#{customer.email}>",
          'ticket.group_id'               => group.id,
          'ticket.owner_id'               => owner.id,
        }
      end
    end
  end
end
