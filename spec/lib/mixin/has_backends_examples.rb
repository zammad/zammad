# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'Mixin::HasBackends' do

  describe '.backends' do
    it 'is a Set' do
      expect(described_class.backends).to be_a(Set)
    end
  end

  it "auto requires #{described_class}::Backend" do
    expect(described_class).to be_const_defined(:Backend)
  end
end
