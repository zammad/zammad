# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe EnsureNoCommasAndAsterisksInTagNames, type: :db_migration do
  let(:tag) do
    Tag::Item
      .new(name: tag_name)
      .tap { |elem| elem.save!(validate: false) }
  end

  context 'when tag name with a comma is present' do
    let(:tag_name) { 'test,name,with,comma' }

    it 'renames tag to have no commas' do
      expect { migrate }
        .to change { tag.reload.name }
        .to 'test name with comma'
    end
  end

  context 'when tag name with an asterisk is present' do
    let(:tag_name) { 'test*name*with*asterisk' }

    it 'renames tag to have no asterisks' do
      expect { migrate }
        .to change { tag.reload.name }
        .to 'test name with asterisk'
    end
  end

  context 'when tag name with both a comma and an asterisk is present' do
    let(:tag_name) { 'test name with*asterisk and,comma' }

    it 'renames tag to have no asterisks and no commas' do
      expect { migrate }
        .to change { tag.reload.name }
        .to 'test name with asterisk and comma'
    end
  end
end
