# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :template do
    name          { Faker::Name.unique.name }
    options       { { 'ticket.title': { value: 'Some dummy title' } } }
    updated_by_id { 1 }
    created_by_id { 1 }
    active        { true }

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
          'ticket.formSenderType' => { value: sender_type },
          'ticket.title'          => { value: title },
          'article.body'          => { value: body },
          'ticket.customer_id'    => { value: customer.id, value_completion: "#{customer.firstname} #{customer.lastname} <#{customer.email}>" },
          'ticket.group_id'       => { value: group.id },
          'ticket.owner_id'       => { value: owner.id },
        }
      end
    end
  end
end
