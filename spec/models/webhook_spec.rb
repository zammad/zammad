require 'rails_helper'

RSpec.describe Webhook, type: :model do

  describe 'check endpoint' do
    subject(:webhook) { create(:webhook, endpoint: endpoint) }

    let(:endpoint) { 'example.com' }

    context 'with missing http type' do
      it 'raise an error' do
        expect { webhook }.to raise_error(Exceptions::UnprocessableEntity, 'Invalid endpoint (no http/https)!')
      end
    end

    context 'with spaces in invalid hostname' do
      let(:endpoint) { 'http://   example.com' }

      it 'raise an error' do
        expect { webhook }.to raise_error(Exceptions::UnprocessableEntity, 'Invalid endpoint!')
      end
    end

    context 'with ? in hostname' do
      let(:endpoint) { 'http://?example.com' }

      it 'raise an error' do
        expect { webhook }.to raise_error(Exceptions::UnprocessableEntity, 'Invalid endpoint (no hostname)!')
      end
    end

    context 'with nil in endpoint' do
      let(:endpoint) { nil }

      it 'raise an error' do
        expect { webhook }.to raise_error(Exceptions::UnprocessableEntity, 'Invalid endpoint!')
      end
    end

  end
end
