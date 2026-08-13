# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# For a provider whose endpoint cannot enumerate its models (Azure AI's deployment based
# endpoints, Zammad AI): the dialog keeps rendering the plain model text field for it, so it never
# asks for a list - and .models says so instead of answering an empty one.
RSpec.shared_examples 'provider/without model listing' do
  describe '.supports_model_listing?' do
    it 'is not supported' do
      expect(provider.supports_model_listing?).to be(false)
    end
  end

  describe '.models' do
    it 'raises NotImplementedError' do
      expect { provider.models(config) }.to raise_error(NotImplementedError)
    end

    it 'does not talk to the endpoint' do
      allow(UserAgent).to receive(:get)

      suppress(NotImplementedError) { provider.models(config) }

      expect(UserAgent).not_to have_received(:get)
    end
  end
end
