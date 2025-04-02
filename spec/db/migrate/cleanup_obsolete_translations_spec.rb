# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CleanupObsoleteTranslations, type: :db_migration do
  def create_parallel_records(locales:, customized: false, is_synchronized_from_codebase: false)
    source = Faker::Name.unique.name
    target_initial = Faker::Name.unique.name
    target = customized ? "#{target_initial}_changed" : target_initial
    Locale.first(locales).each do |locale|
      create(:translation, locale: locale.name, source:, target:, target_initial:, is_synchronized_from_codebase:)
    end
  end

  context 'when purging obsolete records' do
    it 'cleans them up' do
      5.times { create_parallel_records(locales: 20) }
      expect { migrate }.to change(Translation, :count).by(-100)
    end

    it 'keeps codebase strings' do
      create_parallel_records(locales: 20, is_synchronized_from_codebase: true)
      expect { migrate }.not_to change(Translation, :count)
    end

    it 'keeps strings below the locale count threshold' do
      create_parallel_records(locales: 5)
      expect { migrate }.not_to change(Translation, :count)
    end

    it 'keeps customized strings' do
      create_parallel_records(locales: 20)
      create_parallel_records(locales: 20, customized: true)
      Translation.last.tap { |t| t.target = "#{t.target}_changed" }.save!
      expect { migrate }.to change(Translation, :count).by(-20)
    end
  end
end
