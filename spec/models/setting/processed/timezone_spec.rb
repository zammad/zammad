# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Processed::Timezone, type: :model do
  subject(:instance) { described_class.new input }

  let(:input) { [] }

  describe '#process_settings!' do
    context 'when timezone_default is present' do
      let(:input) { [['timezone_default', { 'value' => 'Europe/Berlin' } ]] }

      it 'adds sanitized version' do
        instance.process_settings!

        expect(input).to include(include('timezone_default_sanitized', { 'value' => 'Europe/Berlin' }))
      end
    end

    context 'when timezone_default is present but empty' do
      let(:input) { [['timezone_default', { 'value' => '' } ]] }

      it 'adds sanitized version' do
        instance.process_settings!

        expect(input).to include(include('timezone_default_sanitized', { 'value' => 'UTC' }))
      end
    end

    context 'when timezone_default is not present' do
      let(:input) { [['another', { 'value' => 'setting' } ]] }

      it 'does not add sanitized version' do
        instance.process_settings!

        expect(input).not_to include(include('timezone_default_sanitized'))
      end
    end
  end

  describe '#process_frontend_settings!' do
    context 'when timezone_default is present' do
      let(:input) { { 'timezone_default' => 'Europe/Berlin' } }

      it 'adds sanitized version' do
        instance.process_frontend_settings!

        expect(input).to include 'timezone_default_sanitized' => 'Europe/Berlin'
      end
    end

    context 'when timezone_default is present but empty' do
      let(:input) { { 'timezone_default' => '' } }

      it 'adds sanitized version' do
        instance.process_frontend_settings!

        expect(input).to include 'timezone_default_sanitized' => 'UTC'
      end
    end
  end

  describe '#sanitize_timezone' do
    it 'returns valid timezone' do
      expect(instance.sanitize_timezone('Europe/Vilnius')).to eq 'Europe/Vilnius'
    end

    it 'returns UTC if timezone is missing' do
      expect(instance.sanitize_timezone(nil)).to eq 'UTC'
    end

    it 'returns UTC if timezone is invalid' do
      expect(instance.sanitize_timezone('Europe/Hogwarts')).to eq 'UTC'
    end
  end
end
