require 'rails_helper'
require 'lib/import/import_job_backend_examples'

RSpec.describe Import::Ldap do
  it_behaves_like 'ImportJob backend'

  describe '#queueable?' do

    it 'is queueable if ldap integration is activated' do
      expect(Setting).to receive(:get).with('ldap_integration').and_return(true)
      expect(described_class.queueable?).to be true
    end

    it "isn't queueable if ldap integration is deactivated" do
      expect(Setting).to receive(:get).with('ldap_integration').and_return(false)
      expect(described_class.queueable?).to be false
    end
  end

  describe '.start' do

    it 'starts LDAP import resource factories' do

      import_job = create(:import_job)
      instance   = described_class.new(import_job)

      expect(Setting).to receive(:get).with('ldap_integration').and_return(true)
      expect(Import::Ldap::UserFactory).to receive(:import)

      instance.start
    end
  end
end
