require 'spec_helper'

RSpec.describe OmniAuth::Strategies::MicrosoftOffice365 do
  let(:request)      { double("Request", params: {}, cookies: {}, env: {}) }
  let(:access_token) { instance_double(OAuth2::AccessToken) }
  let(:options)      { { } }

  let(:app) do
    lambda do
      [200, {}, ["Hello."]]
    end
  end

  let(:strategy) do
    OmniAuth::Strategies::MicrosoftOffice365.new(app, "appid", "secret", options)
  end

  before do
    OmniAuth.config.test_mode = true
    allow(strategy).to receive(:request).and_return(request)
    allow(strategy).to receive(:access_token).and_return(access_token)
  end

  after do
    OmniAuth.config.test_mode = false
  end

  describe "#name" do
    it "returns :microsoft_office365" do
      expect(strategy.name).to eq(:microsoft_office365)
    end
  end

  describe "#client_options" do
    context "with defaults" do
      it "uses correct site" do
        expect(strategy.client.site).to eq("https://login.microsoftonline.com")
      end

      it "uses correct authorize_url" do
        expect(strategy.client.authorize_url).to eq("https://login.microsoftonline.com/common/oauth2/v2.0/authorize")
      end

      it "uses correct token_url" do
        expect(strategy.client.token_url).to eq("https://login.microsoftonline.com/common/oauth2/v2.0/token")
      end
    end

    context "with customized client options" do
      let(:options) do
        {
          client_options: {
            "site"          => "https://example.com",
            "authorize_url" => "https://example.com/authorize",
            "token_url"     => "https://example.com/token",
          }
        }
      end

      it "uses customized site" do
        expect(strategy.client.site).to eq("https://example.com")
      end

      it "uses customized authorize_url" do
        expect(strategy.client.authorize_url).to eq("https://example.com/authorize")
      end

      it "uses customized token_url" do
        expect(strategy.client.token_url).to eq("https://example.com/token")
      end
    end
  end

  describe "#authorize_params" do
    let(:options) do
      { authorize_params: { foo: "bar", baz: "zip" } }
    end

    it "uses correct scope and allows to customize authorization parameters" do
      expect(strategy.authorize_params).to match(
        "scope" => "openid email profile https://outlook.office.com/contacts.read",
        "foo" => "bar",
        "baz" => "zip",
        "state" => /\A\h{48}\z/
      )
    end
  end

  describe "#info" do
    let(:profile_response) do
      instance_double(OAuth2::Response, parsed: {
        "@odata.context" => "https://outlook.office.com/api/v2.0/$metadata#Me",
        "@odata.id"      => "https://outlook.office.com/api/v2.0/Users('XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX@XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX')",
        "Id"             => "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX@XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
        "EmailAddress"   => "luke.skywalker@example.com",
        "DisplayName"    => "Skywalker, Luke",
        "Alias"          => "luke.skywalker",
        "MailboxGuid"    => "YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY"
      })
    end

    before do
      expect(access_token).to receive(:get).with("https://outlook.office.com/api/v2.0/me/")
        .and_return(profile_response)
    end

    context "when user provided avatar image" do
      let(:avatar_response) { instance_double(OAuth2::Response, content_type: "image/jpeg", body: "JPEG_STREAM") }

      before do
        expect(access_token).to receive(:get).with("https://outlook.office.com/api/v2.0/me/photo/$value")
          .and_return(avatar_response)
      end

      it "returns a hash containing normalized user data" do
        expect(strategy.info).to match({
          alias: "luke.skywalker",
          display_name: "Skywalker, Luke",
          email: "luke.skywalker@example.com",
          first_name: "Luke",
          last_name: "Skywalker",
          image: Tempfile,
        })
      end

      it "downloads avatar to a local file with appropriate extension" do
        avatar = strategy.info[:image]
        expect(avatar.binmode?).to be_truthy
        expect(avatar.path).to match(/avatar.*\.jpeg\z/)
        expect(avatar.read).to eq("JPEG_STREAM")
      end
    end

    context "when the name is in alternate format" do
      let(:avatar_response) { instance_double(OAuth2::Response, content_type: "image/jpeg", body: "JPEG_STREAM") }

      before do
        expect(access_token).to receive(:get).with("https://outlook.office.com/api/v2.0/me/photo/$value")
          .and_return(avatar_response)
      end

      let(:profile_response) do
        instance_double(OAuth2::Response, parsed: {
          "@odata.context" => "https://outlook.office.com/api/v2.0/$metadata#Me",
          "@odata.id"      => "https://outlook.office.com/api/v2.0/Users('XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX@XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX')",
          "Id"             => "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX@XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
          "EmailAddress"   => "luke.skywalker@example.com",
          "DisplayName"    => "Luke Skywalker",
          "Alias"          => "luke.skywalker",
          "MailboxGuid"    => "YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY"
        })
      end

      it "returns the parsed first and last name correctly" do
        expect(strategy.info).to match({
          alias: "luke.skywalker",
          display_name: "Luke Skywalker",
          email: "luke.skywalker@example.com",
          first_name: "Luke",
          last_name: "Skywalker",
          image: Tempfile,
        })
      end
    end

    context "when user didn't provide avatar image" do
      let(:avatar_response) { instance_double(OAuth2::Response, "error=" => nil, status: 404, parsed: {}, body: '') }

      before do
        expect(access_token).to receive(:get).with("https://outlook.office.com/api/v2.0/me/photo/$value")
          .and_raise(OAuth2::Error, avatar_response)
      end

      it "returns a hash containing normalized user data" do
        expect(strategy.info).to match({
          alias: "luke.skywalker",
          display_name: "Skywalker, Luke",
          email: "luke.skywalker@example.com",
          first_name: "Luke",
          last_name: "Skywalker",
          image: nil,
        })
      end
    end
  end

end
