# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue2345EsAttachmentMaxSizeInMbSettingLowerDefault, type: :db_migration do

  context 'Issue2345EsAttachmentMaxSizeInMbSettingLowerDefault migration' do

    it 'decreases the default value' do
      allow(Setting).to receive(:get).with('es_attachment_max_size_in_mb').and_return(50)
      migrate
      # reset/remove mocks
      RSpec::Mocks.space.proxy_for(Setting).reset
      expect(Setting.get('es_attachment_max_size_in_mb')).not_to be(50)
    end

    it 'preserves custom Setting value' do
      allow(Setting).to receive(:get).with('es_attachment_max_size_in_mb').and_return(5)
      expect { migrate }.not_to change { Setting.get('es_attachment_max_size_in_mb') }
    end

    it 'performs no action for new systems', system_init_done: false do
      expect { migrate }.not_to change { Setting.get('es_attachment_max_size_in_mb') }
    end
  end
end
