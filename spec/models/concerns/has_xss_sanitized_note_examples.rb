RSpec.shared_examples 'HasXssSanitizedNote' do |model_factory:|
  describe 'XSS prevention' do
    context 'with injected JS' do
      subject { create(model_factory, note: 'test 123 <script type="text/javascript">alert("XSS!");</script> <b>some text</b>') }

      it 'strips out <script> tag' do
        expect(subject.note).to eq('test 123 alert("XSS!"); <b>some text</b>')
      end
    end
  end
end
