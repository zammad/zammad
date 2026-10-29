# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe(FormUpdater::Updater) do
  it 'checks that form updater supports a list' do
    expect(described_class.updaters.sort_by(&:name)).to include(FormUpdater::Updater::Ticket::Create,
                                                                FormUpdater::Updater::User::Create,
                                                                FormUpdater::Updater::User::Edit,
                                                                FormUpdater::Updater::Organization::Edit,
                                                                FormUpdater::Updater::KnowledgeBase::Edit,
                                                                FormUpdater::Updater::KnowledgeBase::Category::Create,
                                                                FormUpdater::Updater::KnowledgeBase::Category::Edit)
  end

  it 'requires every updater to declare its permissions' do
    expect { described_class.required_permissions }.to raise_error(RuntimeError, %r{needs to declare})
  end

  context 'with an id for an updater without an object' do
    subject(:updater) do
      FormUpdater::Updater::GuidedSetup::EmailInbound.new(
        context:         { current_user: create(:admin) },
        relation_fields: [],
        meta:            {},
        data:            {},
        id:              Gql::ZammadSchema.id_from_object(create(:ticket)),
      )
    end

    it 'refuses it with a regular error' do
      expect { updater.authorized? }.to raise_error(RuntimeError, %r{has no object type})
    end
  end
end
