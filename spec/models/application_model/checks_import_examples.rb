RSpec.shared_examples 'ApplicationModel::ChecksImport' do
  subject { build(described_class.name.underscore, id: unused_id) }
  let(:unused_id) { described_class.pluck(:id).max * 2 }

  context 'when Setting.get("system_init_done") is true AND Setting.get("import_mode") is false' do
    before { Setting.set('system_init_done', true) }
    before { Setting.set('import_mode', false) }

    it 'prevents explicit setting of #id attribute' do
      expect { subject.save }.to change { subject.id }
    end
  end

  context 'when Setting.get("system_init_done") is false' do
    before { Setting.set('system_init_done', false) }

    it 'allows explicit setting of #id attribute' do
      expect { subject.save }.not_to change { subject.id }
    end
  end

  context 'when Setting.get("import_mode") is true' do
    before { Setting.set('import_mode', true) }

    shared_examples 'importable classes' do
      it 'allows explicit setting of #id attribute' do
        expect { subject.save }.not_to change { subject.id }
      end
    end

    shared_examples 'non-importable classes' do
      it 'prevents explicit setting of #id attribute' do
        expect { subject.save }.to change { subject.id }
      end
    end

    include_examples described_class.importable? ? 'importable classes' : 'non-importable classes'
  end
end
