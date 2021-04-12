# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_collection_update_examples'
require 'models/concerns/has_xss_sanitized_note_examples'

RSpec.describe Permission, type: :model do
  it_behaves_like 'HasCollectionUpdate', collection_factory: :permission
  it_behaves_like 'HasXssSanitizedNote', model_factory: :permission

  describe '.with_parents' do
    context 'when given a simple string (no dots)' do
      it 'returns an array containing only that string' do
        expect(described_class.with_parents('foo')).to eq(['foo'])
      end
    end

    context 'when given a String permission name (dot-delimited identifier)' do
      it 'returns an array of String ancestors (desc. from root)' do
        expect(described_class.with_parents('foo.bar.baz'))
          .to eq(%w[foo foo.bar foo.bar.baz])
      end
    end
  end
end
