# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue2641KbColorChangeLimit, type: :db_migration, db_strategy: :reset do
  subject(:knowledge_base) { create(:knowledge_base) }

  before do
    Setting.create_if_not_exists(
      title:       'Kb active',
      name:        'kb_active',
      area:        'Kb::Core',
      description: 'Defines if KB navbar button is enabled. Updated in KnowledgeBase callback.',
      state:       false,
      preferences: {
        prio:           1,
        trigger:        ['menu:render'],
        authentication: true,
        permission:     ['admin.knowledge_base'],
      },
      frontend:    true
    )

    Setting.create_if_not_exists(
      title:       'Kb active publicly',
      name:        'kb_active_publicly',
      area:        'Kb::Core',
      description: 'Defines if KB navbar button is enabled for users without KB permission. Updated in CanBePublished callback.',
      state:       false,
      preferences: {
        prio:           1,
        trigger:        ['menu:render'],
        authentication: true,
        permission:     [],
      },
      frontend:    true
    )
  end

  it "doesn't change value for existing KB" do
    expect { migrate }
      .to not_change { knowledge_base.color_header }.and not_change { knowledge_base.color_highlight }
  end
end
