require_relative 'spec_helper'

COMPASS_DIR     = Pathname(__FILE__).dirname.join('compass')
STYLESHEETS_DIR = COMPASS_DIR.join('stylesheets')

describe 'Compass integration' do
  after do
    STYLESHEETS_DIR.rmtree if STYLESHEETS_DIR.exist?
  end

  it 'works from config.rb' do
    `cd #{ COMPASS_DIR }; bundle exec compass compile`
    expect(STYLESHEETS_DIR.join('screen.css').read)
      .to eq("a{display:-webkit-flex;display:flex}\n\n" +
             "/*# sourceMappingURL=screen.css.map */")
    expect(STYLESHEETS_DIR.join('screen.css.map').read)
      .to eq('{"version":3,"sources":["../sass/screen.scss"],"names":[],' +
             '"mappings":"AAAA,EACI,qBAAa,AAAb,YAAa,CAAA","file":"screen.css"}')
  end

end
