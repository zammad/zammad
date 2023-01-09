# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::Article::RetrySecurityProcess, :aggregate_failures, type: :graphql do
  before do
    # Import S/MIME mail without certificates present, generating signature verification error.
    Setting.set('smime_integration', true)
    smime_mail = Rails.root.join('spec/fixtures/files/smime/sender_is_signer.eml').read
    allow(ARGF).to receive(:read).and_return(smime_mail)
    Channel::Driver::MailStdin.new
  end

  let(:query) do
    <<~QUERY
      mutation ticketArticleRetrySecurityProcess($articleId: ID!) {
        ticketArticleRetrySecurityProcess(articleId: $articleId) {
          retryResult {
            type
            signingSuccess
            signingMessage
            encryptionSuccess
            encryptionMessage
          }
          article {
            securityState {
              type
              signingSuccess
              signingMessage
              encryptionSuccess
              encryptionMessage
            }
          }
          errors {
            message
            field
          }
        }
      }
    QUERY
  end
  let(:agent)     { create(:agent, groups: [ Group.find_by(name: 'Users')]) }
  let(:customer)  { create(:customer) }
  let(:article)   { Ticket.last.articles.last }
  let(:variables) { { articleId: gql.id(article) } }

  context "when retrying an article's security process" do

    context 'with an agent', authenticated_as: :agent do

      let(:expected_security_state) do
        {
          'type'              => 'S/MIME',
          'signingSuccess'    => true,
          'signingMessage'    => '/emailAddress=smime1@example.com/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com',
          'encryptionSuccess' => false,
          'encryptionMessage' => nil,
        }
      end

      it 'updates security status' do
        expect(article.preferences['security']['sign']).to eq('success' => false, 'comment' => 'Certificate for verification could not be found.')
        # Import missing certificate.
        create(:smime_certificate, :with_private, fixture: 'smime1@example.com')
        gql.execute(query, variables: variables)
        expect(gql.result.data['retryResult']).to eq(expected_security_state)
        expect(gql.result.data['article']['securityState']).to eq(expected_security_state)
      end
    end

    context 'with a customer', authenticated_as: :customer do
      it 'raises an error' do
        gql.execute(query, variables: variables)
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end
end
