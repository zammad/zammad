# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Store::Provider::File do
  before { FileUtils.rm_rf(Rails.root.join('storage/fs', sha[0, 4])) }

  after { FileUtils.rm_rf(Rails.root.join('storage/fs', sha[0, 4])) }

  let(:data)     { 'foo' }
  let(:sha)      { Store::File.checksum(data) }
  let(:filepath) { Rails.root.join('storage/fs/2c26/b46b/68ffc/68ff9/9b453c1/d304134/13422d706483bfa0f98a5e886266e7ae') }

  describe '.get_location' do
    context 'with a valid SHA256 digest' do
      let(:sha) { '0000111122222333334444444555555566666666666666666666666666666666' }

      it 'returns a Pathname matching the SHA digest (split into chunks of 4, 4, 5, 5, 7, 7, & 32 chars)' do
        expect(described_class.get_location(sha))
          .to eq(Rails.root.join('storage/fs/0000/1111/22222/33333/4444444/5555555/66666666666666666666666666666666'))
      end
    end
  end

  describe '.add' do
    context 'when no matching file exists' do
      it 'writes the file to disk' do
        expect { described_class.add(data, sha) }
          .to change { File.exist?(filepath) }.to(true)

        expect(File.read(filepath)).to eq(data)
      end

      it 'sets permissions on the new file to 600' do
        described_class.add(data, sha)

        expect(File.stat(filepath).mode & 0o777).to eq(0o600)
      end
    end

    context 'when a matching file exists' do
      before { FileUtils.mkdir_p(filepath.parent) }

      context 'and its contents match the SHA digest of its filepath' do
        before do
          File.write(filepath, 'foo')
          File.chmod(0o755, filepath)
        end

        it 'sets file permissions to 600' do
          expect { described_class.add(data, sha) }
            .to change { File.stat(filepath).mode & 0o777 }.to(0o600)
        end
      end

      context 'and its contents do NOT match the SHA digest of its filepath' do
        before { File.write(filepath, 'bar') }

        it 'replaces the corrupt file with the specified contents' do
          expect { described_class.add(data, sha) }
            .to change { File.read(filepath) }.to('foo')
        end
      end
    end
  end

  describe '.get' do
    context 'when a file exists for the given SHA digest' do
      before { FileUtils.mkdir_p(filepath.parent) }

      context 'and its contents match the digest' do
        before { File.write(filepath, data) }

        it 'returns the contents of the file' do
          expect(described_class.get(sha)).to eq('foo')
        end
      end

      context 'and its contents do NOT match the digest' do
        before { File.write(filepath, 'bar') }

        it 'raises an error' do
          expect { described_class.get(sha) }
            .to raise_error(StandardError)
        end
      end
    end

    context 'when NO file exists for the given SHA digest' do
      it 'raises an error' do
        expect { described_class.get(sha) }
          .to raise_error(Errno::ENOENT)
      end
    end
  end

  describe '.delete' do
    before do
      FileUtils.mkdir_p(filepath.parent)
      File.write(filepath, data)
    end

    it 'deletes the file' do
      expect { described_class.delete(sha) }
        .to change { File.exist?(filepath) }.to(false)
    end

    context 'when the file’s parent directories contain other files' do
      before { FileUtils.touch(filepath.parent.join('baz')) }

      it 'leaves non-empty subdirectories in place' do
        expect { described_class.delete(sha) }
          .not_to change { Dir.exist?(filepath.parent) }
      end
    end

    context 'when the file’s parent directories contain no other files' do
      it 'deletes empty parent subdirectories, up to /storage/fs' do
        expect { described_class.delete(sha) }
          .to change { Rails.root.join('storage/fs').empty? }.to(true)
      end
    end
  end
end
