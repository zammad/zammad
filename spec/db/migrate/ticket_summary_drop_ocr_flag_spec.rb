# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TicketSummaryDropOCRFlag, :aggregate_failures, type: :db_migration do
  let(:setting) { Setting.find_by(name: 'ai_assistance_ticket_summary_config') }

  def apply_ocr_active(value)
    setting.state_initial = { value: setting.state_initial[:value].merge(ocr_active: !value) }
    setting.state_current = { value: setting.state_current[:value].merge(ocr_active: value) }
    setting.save!
  end

  it 'performs no action for new systems', system_init_done: false do
    apply_ocr_active(true)
    connection = create(:ai_provider_connection)
    connection.reload.update!(default_ocr: false)

    expect { migrate }.not_to raise_error

    expect(setting.reload.state_current[:value]).to have_key(:ocr_active)
    expect(connection.reload.default_ocr).to be(false)
  end

  context 'when the ai_assistance_ticket_summary_config setting does not exist' do
    before { setting.destroy! }

    it 'does not raise' do
      expect { migrate }.not_to raise_error
    end

    it 'treats OCR as active by default' do
      connection = create(:ai_provider_connection)
      connection.reload.update!(default_ocr: false)

      migrate

      expect(connection.reload.default_ocr).to be(true)
    end
  end

  context 'when the ai_assistance_ticket_summary_config setting exists' do
    context 'when ocr_active is missing from the current state value' do
      it 'treats OCR as active by default' do
        connection = create(:ai_provider_connection)
        connection.reload.update!(default_ocr: false)

        migrate

        expect(connection.reload.default_ocr).to be(true)
      end
    end

    context 'when ocr_active is true' do
      before { apply_ocr_active(true) }

      it 'removes ocr_active from the current state value' do
        migrate

        expect(setting.reload.state_current[:value]).not_to have_key(:ocr_active)
      end

      it 'removes ocr_active from the initial state value' do
        migrate

        expect(setting.reload.state_initial[:value]).not_to have_key(:ocr_active)
      end

      it 'keeps the other setting values untouched' do
        migrate

        expect(setting.reload.state_current[:value]).to include(customer_sentiment: true)
      end

      context 'when a default_ocr provider connection exists' do
        it 'keeps it as the default OCR connection' do
          connection = create(:ai_provider_connection, :default_ocr)

          migrate

          expect(connection.reload.default_ocr).to be(true)
        end
      end

      context 'when no default_ocr provider connection exists, but other connections do' do
        it 'promotes the first provider connection to default OCR' do
          first_connection  = create(:ai_provider_connection)
          second_connection = create(:ai_provider_connection)
          first_connection.reload.update!(default_ocr: false)

          migrate

          expect(first_connection.reload.default_ocr).to be(true)
          expect(second_connection.reload.default_ocr).to be(false)
        end
      end

      context 'when there are no provider connections at all' do
        it 'does not raise and creates no connections' do
          expect { migrate }.not_to raise_error
          expect(AI::ProviderConnection.count).to be_zero
        end
      end
    end

    context 'when ocr_active is false' do
      before { apply_ocr_active(false) }

      it 'removes ocr_active from the current state value' do
        migrate

        expect(setting.reload.state_current[:value]).not_to have_key(:ocr_active)
      end

      it 'removes ocr_active from the initial state value' do
        migrate

        expect(setting.reload.state_initial[:value]).not_to have_key(:ocr_active)
      end

      context 'when a default_ocr provider connection exists' do
        it 'clears the default OCR flag on that connection' do
          connection = create(:ai_provider_connection, :default_ocr)

          expect { migrate }.to change { connection.reload.default_ocr }.from(true).to(false)
        end
      end

      context 'when no default_ocr provider connection exists, but other connections do' do
        it 'does not change any connection' do
          first_connection  = create(:ai_provider_connection)
          second_connection = create(:ai_provider_connection)
          first_connection.reload.update!(default_ocr: false)

          migrate

          expect(first_connection.reload.default_ocr).to be(false)
          expect(second_connection.reload.default_ocr).to be(false)
        end
      end

      context 'when there are no provider connections at all' do
        it 'does not raise and creates no connections' do
          expect { migrate }.not_to raise_error
          expect(AI::ProviderConnection.count).to be_zero
        end
      end
    end
  end
end
