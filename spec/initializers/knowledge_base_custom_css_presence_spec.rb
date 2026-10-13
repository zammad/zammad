# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Knowledge base custom CSS presence' do # rubocop:disable RSpec/DescribeClass
  let(:initializer) { Rails.root.join('config/initializers/knowledge_base_custom_css_presence.rb') }
  let(:root)        { Dir.mktmpdir('kb-custom-css', Rails.root.join('tmp')) }
  let(:css_dir)     { File.join(root, 'app/assets/stylesheets/custom_knowledge_base_public') }

  around do |example|
    original = Rails.application.config.knowledge_base_custom_css_present
    example.run
    Rails.application.config.knowledge_base_custom_css_present = original
  end

  before do
    # Resolve the real path before Rails.root points to the temporary directory.
    initializer

    FileUtils.mkdir_p(css_dir)
    File.write(File.join(css_dir, 'README.txt'), 'put your css files in here')

    allow(Rails).to receive(:root).and_return(Pathname.new(root))
  end

  after do
    FileUtils.remove_entry(root)
  end

  def detect_custom_css
    load initializer
    Rails.application.config.knowledge_base_custom_css_present
  end

  it 'detects a css file in the directory' do
    File.write(File.join(css_dir, 'custom.css'), 'body {}')

    expect(detect_custom_css).to be(true)
  end

  it 'detects a css file in a subdirectory' do
    FileUtils.mkdir_p(File.join(css_dir, 'brand'))
    File.write(File.join(css_dir, 'brand/custom.css'), 'body {}')

    expect(detect_custom_css).to be(true)
  end

  it 'detects nothing without css files' do
    expect(detect_custom_css).to be(false)
  end
end
