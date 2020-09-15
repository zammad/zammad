require 'rails_helper'
require 'models/contexts/factory_context'

RSpec.describe Webhook, type: :model do

  subject(:webhook) { create(:webhook) }

  # make sure there's no webhook from seed data
  before { Webhook.all.each(&:full_destroy!) }

  include_context 'factory'

  it { is_expected.to validate_presence_of(:url) }

  describe "Validations" do
    describe "#url" do
      it { is_expected.to be_valid }

      it "accepts HTTP scheme" do
        url = "http://myapi.company.com/webhook"

        expect(build(:webhook, url: url)).to be_valid
      end

      it "accepts HTTPS scheme" do
        url = "https://myapi.company.com/webhook"

        expect(build(:webhook, url: url)).to be_valid
      end

      it "does not accept URL without scheme" do
        url = "myapi.company.com/webhook"

        expect(build(:webhook, url: url)).to_not be_valid
      end

      it "does not accept URL with invalid scheme" do
        url = "ftp://myapi.company.com/webhook"

        expect(build(:webhook, url: url)).to_not be_valid
      end

      it "does not accept only the scheme" do
        url = "https://"

        expect(build(:webhook, url: url)).to_not be_valid
      end
    end
  end
end
