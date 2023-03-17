# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue4018RemoveOldTranslations, type: :db_migration do
  before do
    create(:translation, source: 'FORMAT_DATE', target_initial: 'Datum', target: 'Datum', is_synchronized_from_codebase: false)
  end

  it 'does remove old translations for source "FORMAT_DATE"' do
    migrate
    expect(Translation.where(locale: 'de-de', source: 'FORMAT_DATE').count).to eq(1)
  end
end
