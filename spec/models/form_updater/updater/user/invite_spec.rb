# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'models/form_updater/concerns/checks_core_workflow_examples'

RSpec.describe FormUpdater::Updater::User::Invite do
  subject(:form_updater) do
    described_class.new(
      context:         context,
      meta:            meta,
      data:            data,
      relation_fields: [],
    )
  end

  let(:user)                    { create(:admin) }
  let(:context)                 { { current_user: user } }
  let(:meta)                    { { initial: true, form_id: SecureRandom.uuid } }
  let(:data)                    { {} }

  describe '#resolve' do
    it 'includes roles and preselects Agent role' do
      expect(form_updater.resolve).to include(
        'role_ids' => include(
          options: eq(
            Role.reorder(:id).map do |elem|
              {
                value:       elem.id,
                label:       elem.name,
                description: elem.note,
              }
            end
          )
        )
      )
    end

    it 'includes groups' do
      parent_group   = Group.first
      children_group = create(:group, parent: parent_group)

      expect(form_updater.resolve).to include(
        'group_ids' => include(
          options: include(
            include(
              value:    parent_group.id,
              label:    parent_group.name_last,
              children: include(
                include(
                  value: children_group.id,
                  label: children_group.name_last,
                )
              )
            )
          )
        )
      )
    end
  end

  describe 'CoreWorkflow' do
    let(:resolved_result) { form_updater }

    include_examples 'FormUpdater::ChecksCoreWorkflow', object_name: 'User'
  end
end
