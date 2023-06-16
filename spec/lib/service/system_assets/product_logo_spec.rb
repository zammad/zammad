# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::SystemAssets::ProductLogo do
  let(:base64) { 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==' }
  let(:raw_logo) do
    create(:store,
           object:      'System::Logo',
           o_id:        described_class::PRODUCT_LOGO_RAW,
           data:        'example_raw',
           filename:    'logo_raw',
           preferences: { 'Content-Type' => 'image/png' })
  end

  let(:resized_logo) do
    create(:store,
           object:      'System::Logo',
           o_id:        described_class::PRODUCT_LOGO_RESIZED,
           data:        'example',
           filename:    'logo',
           preferences: { 'Content-Type' => 'image/png' })
  end

  describe '.sendable_asset' do
    it 'returns default logo' do
      expect(described_class.sendable_asset)
        .to have_attributes(
          content:  be_present,
          filename: 'logo.svg',
          type:     'image/svg+xml'
        )
    end

    it 'returns custom logo when present' do
      raw_logo

      expect(described_class.sendable_asset)
        .to have_attributes(
          content:  'example_raw',
          filename: 'logo_raw',
          type:     'image/png'
        )
    end

    it 'returns custom resized logo when present' do
      raw_logo
      resized_logo

      expect(described_class.sendable_asset)
        .to have_attributes(
          content:  'example',
          filename: 'logo',
          type:     'image/png'
        )
    end
  end

  describe '.store_logo' do
    before do
      raw_logo
      resized_logo

      described_class.store_logo(preprocessed)
    end

    let(:preprocessed) { ImageHelper.data_url_attributes base64 }

    it 'sets resized logos to empty' do
      expect(Store.list(object: 'System::Logo', o_id: described_class::PRODUCT_LOGO_RESIZED))
        .to be_blank
    end

    it 'stores raw logo' do
      stored = Store.list(object: 'System::Logo', o_id: described_class::PRODUCT_LOGO_RAW).first

      expect(stored.content).to eq preprocessed[:content]
    end
  end

  describe '.store', aggregate_failures: true do
    before do
      raw_logo
      resized_logo
    end

    it 'stores raw logo' do
      expect { described_class.store(base64, nil) }
        .to change { Store.list(object: 'System::Logo', o_id: described_class::PRODUCT_LOGO_RAW).first.id }

      expect(Store.list(object: 'System::Logo', o_id: described_class::PRODUCT_LOGO_RESIZED)).to be_blank
    end

    it 'stores resized logo' do
      expect { described_class.store(nil, base64) }
        .to change { Store.list(object: 'System::Logo', o_id: described_class::PRODUCT_LOGO_RESIZED).first.id }

      expect(Store.list(object: 'System::Logo', o_id: described_class::PRODUCT_LOGO_RAW)).to be_blank
    end

    it 'stores both logos' do
      expect { described_class.store(base64, base64) }
        .to change { Store.list(object: 'System::Logo', o_id: described_class::PRODUCT_LOGO_RESIZED).first.id }
        .and change { Store.list(object: 'System::Logo', o_id: described_class::PRODUCT_LOGO_RAW).first.id }
    end

    it 'returns timestamp if either logo present' do
      freeze_time
      expect(described_class.store(base64, nil)).to eq Time.current.to_i
    end

    it 'returns nil if both logos are unprocessable' do
      expect(described_class.store(nil, nil)).to be_nil
    end

    it 'does not clear all stored logos when both new logos are unprocessable' do
      described_class.store(nil, nil)

      expect(Store.list(object: 'System::Logo', o_id: described_class::PRODUCT_LOGO_RAW)).to be_present
      expect(Store.list(object: 'System::Logo', o_id: described_class::PRODUCT_LOGO_RESIZED)).to be_present
    end
  end
end
