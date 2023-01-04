# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'HasXssSanitizedNote' do |model_factory:|
  describe 'XSS prevention' do
    context 'with injected JS' do
      subject { create(model_factory, note: 'test 123 <script type="text/javascript">alert("XSS!");</script> <b>some text</b>') }

      before do
        # XSS processing may run into a timeout on slow CI systems, so turn the timeout off for the test.
        stub_const("#{HtmlSanitizer}::PROCESSING_TIMEOUT", nil)
      end

      it 'strips out <script> tag with content' do
        expect(subject.note).to eq('test 123  <b>some text</b>')
      end
    end
  end
end
