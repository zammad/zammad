# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Mail::Encodings do
  # Regression test for https://github.com/zammad/zammad/issues/2456
  # (Mail lib was originally broken, so we patched it.
  # Then, upstream was fixed, whereas our patch broke.)
  describe '.value_decode' do
    it 'decodes us-ascii encoded strings' do
      expect(described_class.value_decode('=?us-ascii?Q?Test?='))
        .to eql('Test')
    end

    it 'decodes utf-8 encoded strings' do
      expect(described_class.value_decode('=?UTF-8?Q? Personal=C3=A4nderung?='))
        .to eql(' Personaländerung')
    end
  end
end
