# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Answer::Translation::Content, current_user_id: 1, type: :model do
  subject(:content) { create(:knowledge_base_answer_translation_content) }

  include_context 'factory'

  it { is_expected.to have_one(:translation) }

  # Detailed excerpt behaviour is covered in spec/models/concerns/has_excerpt_spec.rb;
  # here we only verify the HTML body is fed through to the excerpt logic correctly.
  describe '#body_excerpt' do
    it 'strips HTML and preserves line breaks from block tags' do
      content = described_class.new(body: '<p>First paragraph.</p><p>Second <b>paragraph</b>.</p>')

      expect(content.body_excerpt).to eq("First paragraph.\nSecond paragraph.")
    end

    it 'returns nil when the body is nil' do
      expect(described_class.new(body: nil).body_excerpt).to be_nil
    end
  end

  describe '#body_text_only' do
    def body_text_only_of(body)
      described_class.new(body: body).body_text_only
    end

    it 'breaks paragraphs apart' do
      expect(body_text_only_of('<p>first</p><p>second</p>')).to eq("first\nsecond")
    end

    it 'breaks list items apart' do
      expect(body_text_only_of('<ul><li>one</li><li>two</li></ul>')).to eq("* one\n* two")
    end

    it 'keeps the text of a link and drops its address' do
      expect(body_text_only_of('See <a href="https://example.com">the docs</a>.')).to eq('See the docs.')
    end

    it 'decodes an entity' do
      expect(body_text_only_of('Q&amp;A session')).to eq('Q&A session')
    end

    it 'removes the highlight marks' do
      expect(body_text_only_of("Marked \u{E000}run\u{E001} here")).to eq('Marked run here')
    end

    it 'drops a video widget marker', :aggregate_failures do
      text = body_text_only_of('<p>Watch this:</p><p>( widget: video, provider: mediacms, host: demo.mediacms.io, id: hDHXkdwy0 )</p><p>Done.</p>')

      expect(text).to include('Watch this:').and include('Done.')
      expect(text).not_to include('widget')
    end

    it 'returns an empty string for a nil body' do
      expect(body_text_only_of(nil)).to eq('')
    end
  end

  describe '#search_index_attribute_lookup' do
    it 'indexes the plain body' do
      content = create(:knowledge_base_answer_translation_content, body: '<p>first</p><p>second</p>')

      expect(content.search_index_attribute_lookup['body']).to eq("first\nsecond")
    end
  end

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

    it 'credits the editor who changed the body, not whoever last touched the translation' do
      first_editor  = create(:agent)
      second_editor = create(:agent)

      UserInfo.current_user_id = first_editor.id
      translation.update!(title: 'Updated title') # only touches translation directly, e.g. via its own edit

      UserInfo.current_user_id = second_editor.id
      content.update!(body: 'Updated body') # only touches content, bumped onto translation via the callback

      expect(translation.reload.updated_by_id).to eq(second_editor.id)
    end
  end
end
