# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MigrateCatalanUserPreference, type: :db_migration do
  it 'migrates user preferences from es-ca to ca' do
    user = create(:user, preferences: { locale: 'es-ca' })

    expect { migrate }
      .to change { user.reload.preferences[:locale] }
      .from('es-ca').to('ca')
      .and change { user.reload.updated_at }
  end

  it 'does not touch users with other locales' do
    user = create(:user, preferences: { locale: 'es-mx' })

    expect { migrate }
      .not_to change { user.reload.preferences[:locale] }
  end
end
