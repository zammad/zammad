# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ReservedWordsPerModel, db_strategy: :reset, type: :db_migration do
  let(:attribute) do
    ObjectManager::Attribute.add(
      attributes_for(
        :object_manager_attribute_text,
        object_name:,
        name:        'article'
      ).merge(force: true)
    )
    ObjectManager::Attribute.migration_execute(false)

    ObjectManager::Attribute.get(object: object_name.constantize.to_app_model, name: 'article')
  end

  before { attribute }

  context 'when an attribute called "article" exists in the Ticket model' do
    let(:object_name) { 'Ticket' }

    it 'renames the attribute to "_article"' do
      expect { migrate }.to change { attribute.reload.name }.from('article').to('_article')
    end
  end

  context 'when an attribute called "article" exists in the User model' do
    let(:object_name) { 'User' }

    it 'does not rename the attribute' do
      expect { migrate }.not_to change { attribute.reload.name }
    end
  end
end
