# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/application_model_examples'
require 'models/concerns/can_be_imported_examples'
require 'models/concerns/has_collection_update_examples'
require 'models/concerns/has_xss_sanitized_note_examples'
require 'models/concerns/has_search_index_backend_examples'

RSpec.describe Ticket::Priority, type: :model do
  it_behaves_like 'ApplicationModel'
  it_behaves_like 'CanBeImported'
  it_behaves_like 'HasCollectionUpdate', collection_factory: :ticket_priority
  it_behaves_like 'HasXssSanitizedNote', model_factory: :ticket_priority
  it_behaves_like 'HasSearchIndexBackend', indexed_factory: :ticket_priority

  describe 'Default state' do
    describe 'of whole table:' do
      it 'has exactly one default record' do
        expect(described_class.where(default_create: true)).to be_one
      end
    end
  end

  describe 'attributes' do
    describe '#default_create' do
      it 'cannot be true for more than one record at a time' do
        expect { create(:'ticket/priority', default_create: true) }
          .to change { described_class.find_by(default_create: true).id }
          .and not_change { described_class.where(default_create: true).count }
      end

      it 'cannot be false for all records' do
        create(:'ticket/priority', default_create: true)

        expect { described_class.find_by(default_create: true).destroy }
          .to change { described_class.find_by(default_create: true).id }
          .and not_change { described_class.where(default_create: true).count }
      end

      it 'is not automatically set to the last-created record' do
        expect { create(:'ticket/priority') }
          .not_to change { described_class.find_by(default_create: true).id }
      end
    end
  end
end
