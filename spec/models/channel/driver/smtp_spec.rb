# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative 'using_bcc_examples'

RSpec.describe Channel::Driver::Smtp do
  describe '#prepare_options' do
    let(:instance) { described_class.new }

    describe 'domain' do
      context 'when domain is given' do
        it 'uses the given one' do
          expect(instance.prepare_options({ domain: 'outgoing.com' }, {}))
            .to include(domain: 'outgoing.com')
        end
      end

      context 'when domain is not given' do
        it 'uses FQDN' do
          expect(instance.prepare_options({}, {}))
            .to include(domain: 'zammad.example.com')
        end

        it 'uses FQDN without port number if it was included' do
          Setting.set('fqdn', 'with.port.com:3000')

          expect(instance.prepare_options({}, {}))
            .to include(domain: 'with.port.com')
        end

        it 'uses FROM address domain if FQDN is a local address' do
          Setting.set('fqdn', 'localhost.local')

          expect(instance.prepare_options({}, { from: 'test@example.com' }))
            .to include(domain: 'example.com')
        end

        it 'uses local FQDN if FROM is not set' do
          Setting.set('fqdn', 'localhost.local')

          expect(instance.prepare_options({}, {}))
            .to include(domain: 'localhost.local')
        end
      end
    end
  end

  describe '#build_smtp_params', :aggregate_failures do
    let(:instance) { described_class.new }

    context 'when ssl is set (SMTPS, e.g. port 465) and enable_starttls_auto is also stored' do
      let(:options) do
        {
          host:                 'smtp.example.com',
          port:                 '465',
          domain:               'example.com',
          ssl:                  true,
          ssl_verify:           true,
          enable_starttls_auto: true,
        }
      end

      it 'does not pass enable_starttls_auto to avoid ArgumentError from mail gem 2.9+' do
        result = instance.build_smtp_params(options)
        expect(result).to include(ssl: true)
        expect(result).not_to have_key(:enable_starttls_auto)
      end
    end

    context 'when ssl is not set (STARTTLS, e.g. port 587)' do
      let(:options) do
        {
          host:                 'smtp.example.com',
          port:                 '587',
          enable_starttls_auto: true
        }
      end

      it 'passes enable_starttls_auto' do
        result = instance.build_smtp_params(options)
        expect(result).to include(enable_starttls_auto: true)
        expect(result).not_to have_key(:ssl)
      end
    end
  end

  describe '#deliver' do
    let(:channel)   { create(:email_channel, :smtp, mail_server_user: 'user@example.com') }

    it_behaves_like 'using BCC'

    context 'when an error is raised', aggregate_failures: true do
      before do
        allow_any_instance_of(Mail::Message).to receive(:deliver).and_raise(error)
      end

      context 'when the error is one of the predefined errors' do
        let(:error) { Net::OpenTimeout.new('Could not reach server') }

        it 'raises an error with a humanized message' do
          expect { channel.deliver({}) }
            .to raise_error(Channel::DeliveryError) { |error|
              expect(error.original_error.message)
                .to eq('Network connection to smtp.example.com timed out: Could not reach server')
            }
        end
      end

      context 'when the error is unknown' do
        let(:error) { StandardError.new('custom error message') }

        it 'forwards the error' do
          expect { channel.deliver({}) }
            .to raise_error(Channel::DeliveryError) { |error|
              expect(error.original_error.message).to eq('smtp.example.com: custom error message')
            }
        end
      end

      context 'when it was sending a notification' do
        let(:error)          { Net::SMTPUnknownError.new(error_response, message: 'smtp error') }
        let(:error_response) { Net::SMTP::Response.parse("#{error_code} dummy error") }

        context 'when the error is silenceable' do
          let(:error_code) { 400 }

          it 'raises no error' do
            expect { channel.deliver({}, true) }
              .not_to raise_error
          end
        end

        context 'when the error is not silenceable' do
          let(:error_code) { 123 }

          it 'raises an error' do
            expect { channel.deliver({}, true) }
              .to raise_error(Channel::DeliveryError) { |error|
                expect(error.original_error.message).to eq('smtp.example.com: smtp error')
              }
          end
        end
      end
    end
  end
end
