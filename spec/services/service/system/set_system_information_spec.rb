# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::System::SetSystemInformation do
  let(:service) { described_class.new(data: variables) }

  let(:required_variables) do
    {
      url:          'http://example.com',
      organization: 'Sample'
    }
  end

  describe 'setting locale' do
    context 'when locale is given' do
      let(:variables) { required_variables.merge(locale_default: 'lt') }

      it 'sets locale' do
        expect { service.execute }
          .to change { Setting.get('locale_default') }
          .to('lt')
      end

      it 'does return updated settings' do
        result = service.execute

        expect(result).to include(
          locale_default: 'lt',
          organization:   'Sample',
          http_type:      'http',
          fqdn:           'example.com'
        )
      end
    end

    context 'when locale is given but another parameter is invalid' do
      let(:variables) { required_variables.merge(locale_default: 'lt').tap { _1.delete(:url) } }

      it 'does not set locale' do
        expect { service.execute }.to raise_error(Exceptions::InvalidAttribute)
      end
    end

    context 'when locale is not given' do
      let(:variables) { required_variables }

      it 'does not change locale' do
        expect { service.execute }.not_to change { Setting.get('locale_default') }
      end
    end
  end

  describe 'setting timezone' do
    context 'when timezone is given' do
      let(:variables) { required_variables.merge(timezone_default: 'Europe/Vilnius') }

      it 'sets timezone' do
        expect { service.execute }.to change { Setting.get('timezone_default') }.to('Europe/Vilnius')
      end
    end

    context 'when timezone is not given' do
      let(:variables) { required_variables }

      it 'does not change timezone' do
        expect { service.execute }.not_to change { Setting.get('timezone_default') }
      end
    end
  end

  describe 'setting organization name' do
    context 'when organization name is given' do
      let(:variables) { required_variables }

      it 'sets organization name' do
        expect { service.execute }.to change { Setting.get('organization') }.to('Sample')
      end
    end

    context 'when organization name is given but another parameter is invalid' do
      let(:variables) { required_variables.tap { _1.delete(:url) } }

      it 'does not set organization name' do
        expect { service.execute }.to raise_error(Exceptions::InvalidAttribute)
      end
    end

    context 'when organization name is not valid' do
      let(:variables) { required_variables.merge(organization: ' ') }

      it 'returns an error' do
        expect { service.execute }.to raise_error(Exceptions::MissingAttribute)
      end
    end

    context 'when organization name is not given' do
      let(:variables) { required_variables.tap { _1.delete(:organization) } }

      it 'returns an error' do
        expect { service.execute }.to raise_error(Exceptions::MissingAttribute)
      end
    end
  end

  describe 'setting http type & FQDN' do
    context 'when url is given' do
      let(:variables) { required_variables }

      it 'sets service name' do
        expect { service.execute }
          .to change { [Setting.get('http_type'), Setting.get('fqdn')] }
          .to(['http', 'example.com'])
      end

      context 'when system is online service' do
        before { Setting.set('system_online_service', true) }

        it 'does not set http type & FQDN' do
          expect { service.execute }
            .not_to change { [Setting.get('http_type'), Setting.get('fqdn')] }
        end
      end
    end

    context 'when url is given but another parameter is invalid' do
      let(:variables) { required_variables.tap { _1.delete(:organization) } }

      it 'does not set http type & FQDN' do
        expect { service.execute }.to raise_error(Exceptions::MissingAttribute)
      end
    end

    context 'when url is not valid' do
      let(:variables) { required_variables.merge(url: 'meh') }

      it 'returns an error' do
        expect { service.execute }.to raise_error(Exceptions::InvalidAttribute)
      end
    end

    context 'when url is not given' do
      let(:variables) { required_variables.tap { _1.delete(:url) } }

      it 'returns an error' do
        expect { service.execute }.to raise_error(Exceptions::InvalidAttribute)
      end
    end
  end

  describe 'setting logo' do
    let(:image_data) { Rails.root.join('test/data/image/1000x1000.png').binread }

    before do
      freeze_time

      allow(Service::SystemAssets::ProductLogo)
        .to receive(:store_one)
        .and_call_original
    end

    context 'when logo is given' do
      let(:variables) { required_variables.merge(logo: image_data) }

      it 'sets updates logo and sets logo timestamp' do
        expect { service.execute }
          .to change { Setting.get('product_logo') }
          .to(Time.current.to_i)
      end

      it 'stores both original and resized logos' do
        service.execute
        expect(Service::SystemAssets::ProductLogo).to have_received(:store_one).twice
      end
    end

    context 'when logo is given but another parameter is invalid' do
      let(:variables) { required_variables.merge(logo: image_data).tap { _1.delete(:url) } }

      it 'does not store logo to storage', :aggregate_failures do
        expect { service.execute }.to raise_error(Exceptions::InvalidAttribute)
        expect(Service::SystemAssets::ProductLogo).not_to have_received(:store_one)
      end
    end

    context 'when logo is not given' do
      let(:variables) { required_variables }

      it 'does not set logo timestamp' do
        expect { service.execute }
          .not_to change { Setting.get('product_logo') }
      end

      it 'does not store logo to storage' do
        service.execute

        expect(Service::SystemAssets::ProductLogo).not_to have_received(:store_one)
      end
    end
  end
end
