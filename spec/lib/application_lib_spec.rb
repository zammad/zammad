# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ApplicationLib do
  describe '.load_adapter' do
    it 'loads a class defined directly in the namespace' do
      expect(described_class.load_adapter('Service::GeoIp::Zammad', namespace: Service::GeoIp)).to be(Service::GeoIp::Zammad)
    end

    {
      'KnowledgeBase::MenuItem'      => 'a class of another namespace',
      'Service::GeoIp::ClassMethods' => 'a constant the namespace inherits',
      'Service::GeoIp'               => 'the namespace itself',
      'Service::GeoIp::Unknown'      => 'an unknown class',
    }.each do |name, description|
      it "ignores #{description}" do
        expect(described_class.load_adapter(name, namespace: Service::GeoIp)).to be_nil
      end
    end
  end

  describe '.load_subclass' do
    it 'loads a subclass' do
      expect(described_class.load_subclass('Import::Ldap', base: Import::IntegrationBase)).to be(Import::Ldap)
    end

    {
      'Import::IntegrationBase' => 'the class itself',
      'Import::Zendesk'         => 'a sibling class',
      'Hashie::Mash'            => 'an unrelated class',
      'Import::Unknown'         => 'an unknown class',
    }.each do |name, description|
      it "ignores #{description}" do
        expect(described_class.load_subclass(name, base: Import::IntegrationBase)).to be_nil
      end
    end
  end

  describe '.load_adapter_by_setting' do
    before do
      # A loaded adapter forgets what an earlier example logged for the setting.
      Service::GeoIp.load_adapter_by_setting('geo_ip_backend')

      Setting.set('geo_ip_backend', 'KnowledgeBase::MenuItem', validate: false)
      allow(KnowledgeBase::MenuItem).to receive(:location)
      allow(Rails.logger).to receive(:error)
    end

    it 'does not call a class outside of the loading class and logs it once', :aggregate_failures do
      2.times { expect(Service::GeoIp.location('195.65.29.254')).to be_nil }
      expect(KnowledgeBase::MenuItem).not_to have_received(:location)
      expect(Rails.logger).to have_received(:error).with(%r{'geo_ip_backend' names 'KnowledgeBase::MenuItem'}).once
    end

    it 'logs a rejected value again once the setting changed', :aggregate_failures do
      Service::GeoIp.location('195.65.29.254')
      Setting.set('geo_ip_backend', 'Service::GeoIp::Zammad')
      Service::GeoIp.load_adapter_by_setting('geo_ip_backend')
      Setting.set('geo_ip_backend', 'KnowledgeBase::MenuItem', validate: false)
      Service::GeoIp.location('195.65.29.254')

      expect(Rails.logger).to have_received(:error).with(%r{'geo_ip_backend' names 'KnowledgeBase::MenuItem'}).twice
    end
  end
end
