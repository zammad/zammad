require_relative 'spec_helper'

describe AutoprefixerRails do
  before :all do
    @dir = Pathname(__FILE__).dirname
    @css = @dir.join('app/app/assets/stylesheets/test.css').read
  end

  it "process CSS" do
    expect(AutoprefixerRails.process(@css)).to be_a(AutoprefixerRails::Result)
  end

  it "process CSS for selected browsers" do
    css = "a {\n    tab-size: 2\n}"
    result = AutoprefixerRails.process(css, browsers: ['opera 12'])
    expect(result.css).to eq "a {\n" +
                             "    -o-tab-size: 2;\n" +
                             "       tab-size: 2\n" +
                             "}"
  end

  it "process @supports" do
    css = "@supports (display: flex) { }"
    result = AutoprefixerRails.process(css, browsers: ['chrome 28'])
    expect(result.css).to eq(
      '@supports ((display: -webkit-flex) or (display: flex)) { }')
  end

  it "generates source map" do
    result = AutoprefixerRails.process(@css, map: true)
    expect(result.css).to include('/*# sourceMappingURL=data:')
  end

  it "generates separated source map" do
    result = AutoprefixerRails.process(@css, map: { inline: false })
    expect(result.map).to be_a(String)
  end

  it "uses file name in syntax errors", not_jruby: true do
    expect {
      AutoprefixerRails.process('a {', from: 'a.css')
    }.to raise_error(/a.css:/)
  end

  it "includes sourcesContent by default" do
    map = AutoprefixerRails.process('a{}', map: { inline:  false }).map
    expect(map).to include('sourcesContent')
  end

  it "maps options from Ruby style" do
    map = AutoprefixerRails.process('a{}', map: {
      sources_content: false,
      inline:          false
    }).map

    expect(map).not_to include('sourcesContent')
  end

  it "does not remove old prefixes on request" do
    css    = 'a { -moz-border-radius: 5px; border-radius: 5px }'
    result = AutoprefixerRails.process(css, remove: false)
    expect(result.css).to eq(css)
  end

  it "shows debug" do
    info = AutoprefixerRails.processor(browsers: ['chrome 25']).info
    expect(info).to match(/Browsers:\n  Chrome: 25\n\n/)
    expect(info).to match(/  transition: webkit/)
  end

  it "returns warnings" do
    css    = 'a{background:linear-gradient(top,white,black)}'
    result = AutoprefixerRails.process(css)
    expect(result.warnings).to eq(['<css input>:1:3: Gradient has outdated ' +
      'direction syntax. New syntax is like `to left` instead of `right`.'])
  end

  context 'Sprockets' do
    before :each do
      @assets = Sprockets::Environment.new
      @assets.append_path(@dir.join('app/app/assets/stylesheets'))
      AutoprefixerRails.install(@assets, browsers: ['chrome 25'])
    end

    it "integrates with Sprockets" do
      css = @assets['test.css'].to_s
      expect(css).to eq "a {\n" +
                        "    -webkit-mask: none;\n" +
                        "            mask: none\n" +
                        "}\n"
    end

    it "shows file name from Sprockets", not_jruby: true do
      expect { @assets['wrong.css'] }.to raise_error(/wrong/)
    end

    it "supports disabling", not_jruby: true do
      AutoprefixerRails.uninstall(@assets)
      css = @assets['test.css'].to_s
      expect(css).to eq "a {\n" +
                        "    mask: none\n" +
                        "}\n"
    end

  end
end
