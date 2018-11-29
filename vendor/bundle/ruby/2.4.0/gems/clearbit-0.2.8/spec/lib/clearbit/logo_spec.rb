require 'spec_helper'

describe Clearbit::Logo do
  context 'domain validation' do

    def check_invalid_domain(domain)
    end

    it 'passes for simple domains' do
      expect {
        Clearbit::Logo.url(domain: 'clearbit.com')
      }.to_not raise_error
    end

    it 'passes for dashed domains' do
      expect {
        Clearbit::Logo.url(domain: 'clear-bit.com')
      }.to_not raise_error
    end

    it 'passes for multi-dot TLDs' do
      expect {
        Clearbit::Logo.url(domain: 'bbc.co.uk')
      }.to_not raise_error

      expect {
        Clearbit::Logo.url(domain: 'clear-bit.co.uk')
      }.to_not raise_error
    end

    it 'passes for new-style tlds' do
      expect {
        Clearbit::Logo.url(domain: 'clearbit.museum')
      }.to_not raise_error
    end

    it 'fails for invalid urls' do
      expect {
        Clearbit::Logo.url(domain: 'clearbit')
      }.to raise_error(ArgumentError)
    end
  end
end
