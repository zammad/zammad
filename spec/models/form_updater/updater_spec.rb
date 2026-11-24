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

  context 'with a setting that changes while a list of a relation field is built', :aggregate_failures do
    let(:admin) { create(:admin) }
    let(:owner) { create(:agent, firstname: 'Carla', lastname: 'Agent') }

    def owner_options
      updater = FormUpdater::Updater::GuidedSetup::EmailInbound.new(
        context: { current_user: admin }, relation_fields: [{ name: 'owner_id', relation: 'user', filter_ids: [owner.id] }], meta: {}, data: {}
      )
      updater.authorized?

      updater.resolve[:fields]['owner_id'][:options]
    end

    it 'keeps the list in the format its key names, so that a later request gets its own' do
      # After the key is read and before the list is built: the cache is asked in between.
      changed = false
      allow(Rails.cache).to receive(:read).and_wrap_original do |original, *args|
        if !changed && args.first.to_s.start_with?('FormUpdater::OptionCache')
          changed = true
          Setting.set('user_name_format', 'last_first')
        end

        original.call(*args)
      end

      # Back again once the list is built, before its key is read once more.
      allow(FormUpdater::Relation::Owner).to receive(:new).and_wrap_original do |original, **args|
        original.call(**args).tap do |relation|
          allow(relation).to receive(:options).and_wrap_original do |options|
            options.call.tap { Setting.set('user_name_format', 'first_last') }
          end
        end
      end

      expect(owner_options).to eq([{ value: owner.id, label: 'Carla Agent' }])
      expect(owner_options).to eq([{ value: owner.id, label: 'Carla Agent' }])
    end
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
