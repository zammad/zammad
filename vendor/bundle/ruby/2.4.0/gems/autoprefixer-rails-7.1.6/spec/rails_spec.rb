require_relative 'spec_helper'

describe CssController, type: :controller do
  before :all do
    cache = Rails.root.join('tmp/cache')
    cache.rmtree if cache.exist?
  end

  def test_file(file)
    if Rails.version.split('.').first.to_i >= 5
      get :test, params: { file: file }
    else
      get :test, file: file
    end
  end

  it "integrates with Rails and Sass" do
    test_file 'sass'
    expect(response).to be_success
    clear_css = response.body.gsub("\n", " ").squeeze(" ").strip
    expect(clear_css).to eq "a { -webkit-mask: none; mask: none }"
  end

  if Sprockets::Context.instance_methods.include?(:evaluate)
    it 'supports evaluate' do
      test_file 'evaluate'
      expect(response).to be_success
      clear_css = response.body.gsub("\n", ' ').squeeze(' ').strip
      expect(clear_css).to eq 'a { -webkit-mask: none; mask: none }'
    end
  end

  if sprockets_4?
    it "works with sprockets 4 source maps" do
      get :test, params: { exact_file: 'sass.css.map' }
      expect(response).to be_success

      source_map = JSON.parse(response.body)['sections'].first['map']
      expect(source_map['sources'].first).to match(/loaded.*.sass/)
    end
  end
end

describe 'Rake task' do
  it "shows debug" do
    info = `cd spec/app; bundle exec rake autoprefixer:info`
    expect(info).to match(/Browsers:\n  Chrome: 25\n\n/)
    expect(info).to match(/  transition: webkit/)
  end
end
