# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe EmailHelper::Idn do
  let(:addresses) do
    [
      {
        unicode: 'John Doe 😃 <john.doe@doe😃.org>',
        ascii:   'John Doe 😃 <john.doe@xn--doe-5h33b.org>'
      },
      {
        unicode: 'John Doe 😃 john.doe@doe😃.org',
        ascii:   'John Doe 😃 john.doe@xn--doe-5h33b.org'
      },
      {
        unicode: 'John Doe 😃 john.doe@doe.org',
        ascii:   'John Doe 😃 john.doe@doe.org'
      },
      {
        unicode: 'John Doe 😃 <john.doe@doe.org>',
        ascii:   'John Doe 😃 <john.doe@doe.org>'
      },
      {
        unicode: 'John Doe 😃 <john.doe@doe😃.org> smiley man',
        ascii:   'John Doe 😃 <john.doe@xn--doe-5h33b.org> smiley man'
      },
      {
        unicode: 'John Doe 😃 john.doe@doe😃.org smiley man',
        ascii:   'John Doe 😃 john.doe@xn--doe-5h33b.org smiley man'
      },
      {
        unicode: 'John Doe 😃 john.doe@doe.org smiley man',
        ascii:   'John Doe 😃 john.doe@doe.org smiley man'
      },
      {
        unicode: 'John Doe 😃 <john.doe@doe.org> smiley man',
        ascii:   'John Doe 😃 <john.doe@doe.org> smiley man'
      },
      {
        unicode: '<john.doe@doe😃.org>',
        ascii:   '<john.doe@xn--doe-5h33b.org>'
      },
      {
        unicode: 'john.doe@doe😃.org',
        ascii:   'john.doe@xn--doe-5h33b.org'
      },
      {
        unicode: 'john.doe@doe.org',
        ascii:   'john.doe@doe.org'
      },
      {
        unicode: '<john.doe@doe.org>',
        ascii:   '<john.doe@doe.org>'
      },
      {
        unicode: 'John Doe 😃 john.doe@doe😃.org @smiley man',
        ascii:   'John Doe 😃 john.doe@xn--doe-5h33b.org @smiley man'
      }
    ]
  end

  describe '#to_ascii' do
    it 'converts correctly' do
      addresses.each do |address|
        expect(described_class.to_ascii(address[:unicode])).to eql(address[:ascii])
      end
    end
  end

  describe '#to_unicode' do
    it 'converts correctly' do
      addresses.each do |address|
        expect(described_class.to_unicode(address[:ascii])).to eql(address[:unicode])
      end
    end
  end
end
