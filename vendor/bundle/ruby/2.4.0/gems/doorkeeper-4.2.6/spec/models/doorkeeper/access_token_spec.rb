require 'spec_helper_integration'

module Doorkeeper
  describe AccessToken do
    subject { FactoryGirl.build(:access_token) }

    it { expect(subject).to be_valid }

    it_behaves_like 'an accessible token'
    it_behaves_like 'a revocable token'
    it_behaves_like 'a unique token' do
      let(:factory_name) { :access_token }
    end

    module CustomGeneratorArgs
      def self.generate
      end
    end

    describe :generate_token do
      it 'generates a token using the default method' do
        FactoryGirl.create :access_token

        token = FactoryGirl.create :access_token
        expect(token.token).to be_a(String)
      end

      it 'generates a token using a custom object' do
        eigenclass = class << CustomGeneratorArgs; self; end
        eigenclass.class_eval do
          remove_method :generate
        end
        module CustomGeneratorArgs
          def self.generate(opts = {})
            "custom_generator_token_#{opts[:resource_owner_id]}"
          end
        end

        Doorkeeper.configure do
          orm DOORKEEPER_ORM
          access_token_generator "Doorkeeper::CustomGeneratorArgs"
        end

        token = FactoryGirl.create :access_token
        expect(token.token).to match(%r{custom_generator_token_\d+})
      end

      it 'allows the custom generator to access the application details' do
        eigenclass = class << CustomGeneratorArgs; self; end
        eigenclass.class_eval do
          remove_method :generate
        end
        module CustomGeneratorArgs
          def self.generate(opts = {})
            "custom_generator_token_#{opts[:application].name}"
          end
        end

        Doorkeeper.configure do
          orm DOORKEEPER_ORM
          access_token_generator "Doorkeeper::CustomGeneratorArgs"
        end

        token = FactoryGirl.create :access_token
        expect(token.token).to match(%r{custom_generator_token_Application \d+})
      end

      it 'allows the custom generator to access the scopes' do
        eigenclass = class << CustomGeneratorArgs; self; end
        eigenclass.class_eval do
          remove_method :generate
        end
        module CustomGeneratorArgs
          def self.generate(opts = {})
            "custom_generator_token_#{opts[:scopes].count}_#{opts[:scopes]}"
          end
        end

        Doorkeeper.configure do
          orm DOORKEEPER_ORM
          access_token_generator "Doorkeeper::CustomGeneratorArgs"
        end

        token = FactoryGirl.create :access_token, scopes: 'public write'

        expect(token.token).to eq 'custom_generator_token_2_public write'
      end

      it 'allows the custom generator to access the expiry length' do
        eigenclass = class << CustomGeneratorArgs; self; end
        eigenclass.class_eval do
          remove_method :generate
        end
        module CustomGeneratorArgs
          def self.generate(opts = {})
            "custom_generator_token_#{opts[:expires_in]}"
          end
        end

        Doorkeeper.configure do
          orm DOORKEEPER_ORM
          access_token_generator "Doorkeeper::CustomGeneratorArgs"
        end

        token = FactoryGirl.create :access_token
        expect(token.token).to eq 'custom_generator_token_7200'
      end

      it 'allows the custom generator to access the created time' do
        module CustomGeneratorArgs
          def self.generate(opts = {})
            "custom_generator_token_#{opts[:created_at].to_i}"
          end
        end

        Doorkeeper.configure do
          orm DOORKEEPER_ORM
          access_token_generator "Doorkeeper::CustomGeneratorArgs"
        end

        token = FactoryGirl.create :access_token
        created_at = token.created_at
        expect(token.token).to eq "custom_generator_token_#{created_at.to_i}"
      end

      it 'raises an error if the custom object does not support generate' do
        module NoGenerate
        end

        Doorkeeper.configure do
          orm DOORKEEPER_ORM
          access_token_generator "Doorkeeper::NoGenerate"
        end

        expect { FactoryGirl.create :access_token }.to(
          raise_error(Doorkeeper::Errors::UnableToGenerateToken))
      end

      it 'raises an error if the custom object does not exist' do
        Doorkeeper.configure do
          orm DOORKEEPER_ORM
          access_token_generator "Doorkeeper::NotReal"
        end

        expect { FactoryGirl.create :access_token }.to(
          raise_error(Doorkeeper::Errors::TokenGeneratorNotFound))
      end
    end

    describe :refresh_token do
      it 'has empty refresh token if it was not required' do
        token = FactoryGirl.create :access_token
        expect(token.refresh_token).to be_nil
      end

      it 'generates a refresh token if it was requested' do
        token = FactoryGirl.create :access_token, use_refresh_token: true
        expect(token.refresh_token).not_to be_nil
      end

      it 'is not valid if token exists' do
        token1 = FactoryGirl.create :access_token, use_refresh_token: true
        token2 = FactoryGirl.create :access_token, use_refresh_token: true
        token2.refresh_token = token1.refresh_token
        expect(token2).not_to be_valid
      end

      it 'expects database to raise an error if refresh tokens are the same' do
        token1 = FactoryGirl.create :access_token, use_refresh_token: true
        token2 = FactoryGirl.create :access_token, use_refresh_token: true
        expect do
          token2.refresh_token = token1.refresh_token
          token2.save(validate: false)
        end.to raise_error(uniqueness_error)
      end
    end

    describe 'validations' do
      it 'is valid without resource_owner_id' do
        # For client credentials flow
        subject.resource_owner_id = nil
        expect(subject).to be_valid
      end

      it 'is valid without application_id' do
        # For resource owner credentials flow
        subject.application_id = nil
        expect(subject).to be_valid
      end
    end

    describe '#same_credential?' do

      context 'with default parameters' do

        let(:resource_owner_id) { 100 }
        let(:application)    { FactoryGirl.create :application }
        let(:default_attributes) do
          { application: application, resource_owner_id: resource_owner_id }
        end
        let(:access_token1) { FactoryGirl.create :access_token, default_attributes }

        context 'the second token has the same owner and same app' do
          let(:access_token2) { FactoryGirl.create :access_token, default_attributes }
          it 'success' do
            expect(access_token1.same_credential?(access_token2)).to be_truthy
          end
        end

        context 'the second token has same owner and different app' do
          let(:other_application) { FactoryGirl.create :application }
          let(:access_token2) { FactoryGirl.create :access_token, application: other_application, resource_owner_id: resource_owner_id }

          it 'fail' do
            expect(access_token1.same_credential?(access_token2)).to be_falsey
          end
        end

        context 'the second token has different owner and different app' do

          let(:other_application) { FactoryGirl.create :application }
          let(:access_token2) { FactoryGirl.create :access_token, application: other_application, resource_owner_id: 42 }

          it 'fail' do
            expect(access_token1.same_credential?(access_token2)).to be_falsey
          end
        end

        context 'the second token has different owner and same app' do
          let(:access_token2) { FactoryGirl.create :access_token, application: application, resource_owner_id: 42 }

          it 'fail' do
            expect(access_token1.same_credential?(access_token2)).to be_falsey
          end
        end
      end
    end

    describe '#acceptable?' do
      context 'a token that is not accessible' do
        let(:token) { FactoryGirl.create(:access_token, created_at: 6.hours.ago) }

        it 'should return false' do
          expect(token.acceptable?(nil)).to be false
        end
      end

      context 'a token that has the incorrect scopes' do
        let(:token) { FactoryGirl.create(:access_token) }

        it 'should return false' do
          expect(token.acceptable?(['public'])).to be false
        end
      end

      context 'a token is acceptable with the correct scopes' do
        let(:token) do
          token = FactoryGirl.create(:access_token)
          token[:scopes] = 'public'
          token
        end

        it 'should return true' do
          expect(token.acceptable?(['public'])).to be true
        end
      end
    end

    describe '.revoke_all_for' do
      let(:resource_owner) { double(id: 100) }
      let(:application)    { FactoryGirl.create :application }
      let(:default_attributes) do
        { application: application, resource_owner_id: resource_owner.id }
      end

      it 'revokes all tokens for given application and resource owner' do
        FactoryGirl.create :access_token, default_attributes
        AccessToken.revoke_all_for application.id, resource_owner
        AccessToken.all.each do |token|
          expect(token).to be_revoked
        end
      end

      it 'matches application' do
        FactoryGirl.create :access_token, default_attributes.merge(application: FactoryGirl.create(:application))
        AccessToken.revoke_all_for application.id, resource_owner
        expect(AccessToken.all).not_to be_empty
      end

      it 'matches resource owner' do
        FactoryGirl.create :access_token, default_attributes.merge(resource_owner_id: 90)
        AccessToken.revoke_all_for application.id, resource_owner
        expect(AccessToken.all).not_to be_empty
      end
    end

    describe '.matching_token_for' do
      let(:resource_owner_id) { 100 }
      let(:application)       { FactoryGirl.create :application }
      let(:scopes) { Doorkeeper::OAuth::Scopes.from_string('public write') }
      let(:default_attributes) do
        {
          application: application,
          resource_owner_id: resource_owner_id,
          scopes: scopes.to_s
        }
      end

      it 'returns only one token' do
        token = FactoryGirl.create :access_token, default_attributes
        last_token = AccessToken.matching_token_for(application, resource_owner_id, scopes)
        expect(last_token).to eq(token)
      end

      it 'accepts resource owner as object' do
        resource_owner = double(to_key: true, id: 100)
        token = FactoryGirl.create :access_token, default_attributes
        last_token = AccessToken.matching_token_for(application, resource_owner, scopes)
        expect(last_token).to eq(token)
      end

      it 'accepts nil as resource owner' do
        token = FactoryGirl.create :access_token, default_attributes.merge(resource_owner_id: nil)
        last_token = AccessToken.matching_token_for(application, nil, scopes)
        expect(last_token).to eq(token)
      end

      it 'excludes revoked tokens' do
        FactoryGirl.create :access_token, default_attributes.merge(revoked_at: 1.day.ago)
        last_token = AccessToken.matching_token_for(application, resource_owner_id, scopes)
        expect(last_token).to be_nil
      end

      it 'matches the application' do
        FactoryGirl.create :access_token, default_attributes.merge(application: FactoryGirl.create(:application))
        last_token = AccessToken.matching_token_for(application, resource_owner_id, scopes)
        expect(last_token).to be_nil
      end

      it 'matches the resource owner' do
        FactoryGirl.create :access_token, default_attributes.merge(resource_owner_id: 2)
        last_token = AccessToken.matching_token_for(application, resource_owner_id, scopes)
        expect(last_token).to be_nil
      end

      it 'matches token with fewer scopes' do
        FactoryGirl.create :access_token, default_attributes.merge(scopes: 'public')
        last_token = AccessToken.matching_token_for(application, resource_owner_id, scopes)
        expect(last_token).to be_nil
      end

      it 'matches token with different scopes' do
        FactoryGirl.create :access_token, default_attributes.merge(scopes: 'public email')
        last_token = AccessToken.matching_token_for(application, resource_owner_id, scopes)
        expect(last_token).to be_nil
      end

      it 'matches token with more scopes' do
        FactoryGirl.create :access_token, default_attributes.merge(scopes: 'public write email')
        last_token = AccessToken.matching_token_for(application, resource_owner_id, scopes)
        expect(last_token).to be_nil
      end

      it 'matches application scopes' do
        application = FactoryGirl.create :application, scopes: "private read"
        FactoryGirl.create :access_token, default_attributes.merge(
          application: application
        )
        last_token = AccessToken.matching_token_for(application, resource_owner_id, scopes)
        expect(last_token).to be_nil
      end

      it 'returns the last created token' do
        FactoryGirl.create :access_token, default_attributes.merge(created_at: 1.day.ago)
        token = FactoryGirl.create :access_token, default_attributes
        last_token = AccessToken.matching_token_for(application, resource_owner_id, scopes)
        expect(last_token).to eq(token)
      end

      it 'returns as_json hash' do
        token = FactoryGirl.create :access_token, default_attributes
        token_hash = {
          resource_owner_id:  token.resource_owner_id,
          scopes:             token.scopes,
          expires_in_seconds: token.expires_in_seconds,
          application:        { uid: token.application.uid },
          created_at:         token.created_at.to_i,
        }
        expect(token.as_json).to eq token_hash
      end
    end

  end
end
