# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Answer::Translation::Content, current_user_id: 1, type: :model do
  subject(:content) { create(:knowledge_base_answer_translation_content) }

  include_context 'factory'

  it { is_expected.to have_one(:translation) }

  describe '#touch_translation' do
    let(:translation) { content.translation }

    before { translation } # create eagerly, before travel, so timestamps have a real gap to move across

    it 'updates both updated_at and edited_at on the translation when the body changes' do
      travel(1.hour) # time is frozen: if we don't travel forward, pre- and post-update values will be the same

      expect { content.update!(body: 'Updated body') }
        .to change { translation.reload.updated_at }
        .and change { translation.reload.edited_at }
    end

    it 'updates updated_at when content is saved without the body changing' do
      travel(1.hour) # time is frozen: if we don't travel forward, pre- and post-update values will be the same

      expect { content.save! }
        .to change { translation.reload.updated_at }
    end

    it 'leaves edited_at unchanged when content is saved without the body changing' do
      travel(1.hour) # time is frozen: if we don't travel forward, pre- and post-update values will be the same

      expect { content.save! }
        .not_to change { translation.reload.edited_at }
    end
  end
end
