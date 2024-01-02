# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/validations/object_manager/attribute_validator/backend_examples'

RSpec.describe Validations::DataPrivacyTaskValidator do
  subject(:task) { described_class.new }

  let(:deletable) { create(:customer) }
  let(:record)    { build(:data_privacy_task, deletable: deletable) }

  it 'valid record passes' do
    task.validate(record)

    expect(record.errors).to be_blank
  end

  describe 'validating deletable type' do
    context 'when deletable is user' do
      let(:deletable) { create(:agent) }

      it 'passes' do
        task.validate(record)

        expect(record.errors).to be_blank
      end
    end

    context 'when deletable is ticket' do
      let(:deletable) { create(:ticket) }

      it 'passes' do
        task.validate(record)

        expect(record.errors).to be_blank
      end
    end

    context 'when deletable is other type' do
      let(:deletable) { create(:ticket_article) }

      it 'adds error' do
        task.validate(record)

        expect(record.errors.full_messages).to include('Data privacy task allows to delete a user or a ticket only.')
      end
    end
  end

  describe 'validating if a similar task exists' do
    it 'adds error if task for the same deletable exists' do
      create(:data_privacy_task, deletable: deletable)

      task.validate(record)

      expect(record.errors.full_messages).to include('Selected object is already queued for deletion.')
    end

    it 'passes if existing task is marked as failed' do
      create(:data_privacy_task, deletable: deletable, state: 'failed')

      task.validate(record)

      expect(record.errors).to be_blank
    end

    it 'passes if another task exists' do
      create(:data_privacy_task, deletable: create(:customer))

      task.validate(record)

      expect(record.errors).to be_blank
    end
  end

  describe 'validating user object' do
    it 'adds error if deleting current user', current_user_id: -> { deletable.id } do
      task.validate(record)

      expect(record.errors.full_messages).to include('It is not possible to delete your current account.')
    end

    context 'when deleting a system user' do
      let(:deletable) { User.find_by(id: 1) }

      it 'adds error' do
        task.validate(record)

        expect(record.errors.full_messages).to include('It is not possible to delete the system user.')
      end
    end

    context 'when deleting an admin' do
      let(:deletable) { create(:admin) }

      before { deletable }

      it 'adds error if deleting last admin user' do
        task.validate(record)

        expect(record.errors.full_messages).to include('It is not possible to delete the last account with admin permissions.')
      end

      context 'when other admin exists' do
        let(:other_admin) { create(:admin) }

        before { other_admin }

        it 'passes' do
          task.validate(record)

          expect(record.errors).to be_blank
        end

        it 'adds error if other admins are queued for deletion' do
          create(:data_privacy_task, deletable: other_admin)

          task.validate(record)

          expect(record.errors.full_messages).to include('It is not possible to delete the last account with admin permissions.')
        end
      end
    end
  end
end
