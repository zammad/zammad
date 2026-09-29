# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Expects `generated_file` to generate the file and return it.
#   Compares the entries of the temporary directory instead of counting them,
#   as other temporary files may be removed by the GC in the meantime.
RSpec.shared_examples 'not leaving the generated file on disk' do |prefix:|
  it 'does not leave the generated file on disk' do
    entries_before = Dir.children(Dir.tmpdir)
    generated_file

    expect((Dir.children(Dir.tmpdir) - entries_before).grep(%r{\A#{Regexp.escape(prefix)}})).to be_empty
  end
end
