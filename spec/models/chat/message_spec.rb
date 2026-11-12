# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Chat::Message, type: :model do
  describe '#content' do
    subject(:message) { create(:'chat/message', content: content) }

    let(:png)  { 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==' }
    let(:jpeg) { 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA=' }

    context 'with images embedded by the chat widget' do
      let(:content) { %(<div>Look:</div><img style="width: 100%; max-width: 230px;" src="#{png}"><img style="width: 100%; max-width: 230px;" src="#{jpeg}">) }

      let(:images) { Nokogiri::HTML.fragment(message.content).css('img') }

      it 'keeps them with their source' do
        expect(images.pluck('src')).to eq([png, jpeg])
      end

      it 'keeps the size the widget gave them' do
        expect(images.pluck('style')).to all(include('max-width').and(include('230px')))
      end
    end

    context 'with a script next to the text' do
      let(:content) { '<div>Hello</div><script>alert(1)</script>' }

      it 'removes it' do
        expect(message.content).to include('Hello').and(not_include('script'))
      end
    end
  end
end
