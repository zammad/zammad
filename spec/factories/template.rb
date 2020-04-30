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
      customer { create(:customer_user) }
      group { Group.first }
      owner { create(:agent_user) }
    end

    trait :dummy_data do
      options do
        {
          'formSenderType' => sender_type,
          'title'          => title,
          'body'           => body,
          'customer_id'    => customer.id,
          'group_id'       => group.id,
          'owner_id'       => owner.id,
        }
      end
    end
  end
end
