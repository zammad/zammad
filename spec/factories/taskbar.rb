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

    # A create screen has no record yet, so its key carries a UUID instead of an id, and the
    #   locale of the draft rides in the params (one draft is one translation).
    trait :with_new_knowledge_base_answer do
      transient do
        tab_id     { SecureRandom.uuid }
        kb_locale  { 'en-us' }
      end

      key                      { "KnowledgeBaseAnswerCreateScreen-#{tab_id}" }
      add_attribute(:callback) { 'KnowledgeBaseAnswerCreate' }
      params                   { { id: tab_id, locale: kb_locale } }
    end

    # An answer is edited one translation at a time, so its edit tab carries the locale as the
    #   qualifier of the answer's key - the answer stays the entity of the tab.
    trait :with_knowledge_base_answer do
      transient do
        answer    { create(:knowledge_base_answer) } # rubocop:disable FactoryBot/FactoryAssociationWithStrategy
        kb_locale { 'en-us' }
      end

      key                      { Taskbar.entity_key(answer, kb_locale) }
      add_attribute(:callback) { 'KnowledgeBaseAnswerEdit' }
      params                   { { answer_id: answer.id, locale: kb_locale } }
    end
  end
end
