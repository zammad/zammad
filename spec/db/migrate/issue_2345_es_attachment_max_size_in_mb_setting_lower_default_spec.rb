# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue2345EsAttachmentMaxSizeInMbSettingLowerDefault, type: :db_migration do

  context 'Issue2345EsAttachmentMaxSizeInMbSettingLowerDefault migration', system_init_done: true do
    it 'decreases the default value' do
      Setting.set('es_attachment_max_size_in_mb', 50)
      expect { migrate }.to change { Setting.get('es_attachment_max_size_in_mb') }.from(50).to(10)
    end

    it 'preserves custom Setting value' do
      Setting.set('es_attachment_max_size_in_mb', 5)
      expect { migrate }.not_to change { Setting.get('es_attachment_max_size_in_mb') }.from(5)
    end

    it 'performs no action for new systems', system_init_done: false do
      Setting.set('es_attachment_max_size_in_mb', 50)
      expect { migrate }.not_to change { Setting.get('es_attachment_max_size_in_mb') }.from(50)
    end
  end
end
