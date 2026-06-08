# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :taskbar do
    key                      { "Ticket-#{Faker::Number.unique.number(digits: 5)}" }
    add_attribute(:callback) { 'TicketZoom' }
    params                   { {} }
    state                    { nil }
    prio                     { 1 }
    notify                   { false }
    user_id                  { 1 }

    trait :with_ticket do
      transient do
        ticket { create(:ticket) } # rubocop:disable FactoryBot/FactoryAssociationWithStrategy
      end

      key    { "Ticket-#{ticket.id}" }
      params { { ticket_id: ticket.id } }
    end

    trait :with_user do
      transient do
        user { create(:user) } # rubocop:disable FactoryBot/FactoryAssociationWithStrategy
      end

      key    { "User-#{user.id}" }
      params { { user_id: user.id } }
    end

    trait :with_organization do
      transient do
        organization { create(:organization) } # rubocop:disable FactoryBot/FactoryAssociationWithStrategy
      end

      key    { "Organization-#{organization.id}" }
      params { { organization_id: organization.id } }
    end

    trait :with_search do
      key { 'Search' }
    end

    trait :with_new_ticket do
      key { "TicketCreateScreen-#{Faker::Number.unique.number(digits: 5)}" }
    end
  end
end
