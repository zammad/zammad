require 'rails_helper'
require 'models/application_model_examples'

RSpec.describe Ticket::Priority, type: :model do
  it_behaves_like 'ApplicationModel'

  describe 'Default state' do
    describe 'of whole table:' do
      it 'has exactly one default record' do
        expect(Ticket::Priority.where(default_create: true)).to be_one
      end
    end
  end

  describe 'attributes' do
    describe '#default_create' do
      it 'cannot be true for more than one record at a time' do
        expect { create(:'ticket/priority', default_create: true) }
          .to change { Ticket::Priority.find_by(default_create: true).id }
          .and change { Ticket::Priority.where(default_create: true).count }.by(0)
      end

      it 'cannot be false for all records' do
        create(:'ticket/priority', default_create: true)

        expect { Ticket::Priority.find_by(default_create: true).destroy }
          .to change { Ticket::Priority.find_by(default_create: true).id }
          .and change { Ticket::Priority.where(default_create: true).count }.by(0)
      end

      it 'is not automatically set to the last-created record' do
        expect { create(:'ticket/priority') }
          .not_to change { Ticket::Priority.find_by(default_create: true).id }
      end
    end
  end
end
