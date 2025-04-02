# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Validations::OutOfOfficeValidator do
  subject(:validator) { described_class.new }

  let(:record)      { create(:agent, :ooo, ooo_agent: other_agent) }
  let(:other_agent) { create(:user) }

  before { record.out_of_office = out_of_office }

  context 'when out of office is set to true' do
    let(:out_of_office) { true }

    it 'requires start date' do
      record.out_of_office_start_at = nil

      validator.validate(record)

      expect(record.errors).to be_added(:out_of_office_start_at, :blank)
    end

    it 'requires end date' do
      record.out_of_office_end_at = nil

      validator.validate(record)

      expect(record.errors).to be_added(:out_of_office_end_at, :blank)
    end

    it 'requires logical date range' do
      record.out_of_office_start_at = Date.parse('2011-03-03')
      record.out_of_office_end_at   = Date.parse('2011-02-03')

      validator.validate(record)

      expect(record.errors.full_messages).to include(%r{has to be earlier than or equal to})
    end

    it 'allows single day range' do
      record.out_of_office_start_at = Date.parse('2011-03-03')
      record.out_of_office_end_at   = Date.parse('2011-03-03')

      validator.validate(record)

      expect(record.errors).to be_blank
    end

    it 'requires replacement agent' do
      record.out_of_office_replacement_id = nil

      validator.validate(record)

      expect(record.errors).to be_added(:out_of_office_replacement_id, :blank)
    end

    it 'requires valid replacement agent' do
      record.out_of_office_replacement_id = User.maximum(:id).next

      validator.validate(record)

      expect(record.errors).to be_added(:out_of_office_replacement_id, :invalid)
    end
  end

  context 'when out of office is set to false' do
    let(:out_of_office) { false }

    it 'does not require start date' do
      record.out_of_office_start_at = nil

      validator.validate(record)

      expect(record.errors).to be_blank
    end

    it 'does not require end date' do
      record.out_of_office_end_at = nil

      validator.validate(record)

      expect(record.errors).to be_blank
    end

    it 'does not check date range' do
      record.out_of_office_start_at = Date.parse('2011-02-03')
      record.out_of_office_end_at   = Date.parse('2011-03-03')

      validator.validate(record)

      expect(record.errors).to be_blank
    end

    it 'does not require replacement agent' do
      record.out_of_office_replacement_id = nil

      validator.validate(record)

      expect(record.errors).to be_blank
    end

    it 'allows to set dates and replacement agent' do
      validator.validate(record)

      expect(record.errors).to be_blank
    end

    it 'prevents assigning non existant user' do
      record.out_of_office_replacement_id = User.maximum(:id).next

      validator.validate(record)

      expect(record.errors).to be_added(:out_of_office_replacement_id, :invalid)
    end
  end
end
