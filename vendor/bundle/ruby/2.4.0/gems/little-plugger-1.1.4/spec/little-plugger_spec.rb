require File.join(File.dirname(__FILE__), %w[spec_helper])

describe LittlePlugger do

  it "converts a string from camel-case to underscore" do
    expect(LittlePlugger.underscore('FooBarBaz')).to eq('foo_bar_baz')
    expect(LittlePlugger.underscore('CouchDB')).to eq('couch_db')
    expect(LittlePlugger.underscore('FOOBar')).to eq('foo_bar')
    expect(LittlePlugger.underscore('Foo::Bar::BazBuz')).to eq('foo/bar/baz_buz')
  end

  it "generates a default plugin path" do
    expect(LittlePlugger.default_plugin_path(LittlePlugger)).to eq('little_plugger/plugins')
    expect(LittlePlugger.default_plugin_path(Process::Status)).to eq('process/status/plugins')
  end

  it "generates a default plugin module" do
    expect(LittlePlugger.default_plugin_module('little_plugger')).to eq(LittlePlugger)
    expect {LittlePlugger.default_plugin_module('little_plugger/plugins')}.to \
        raise_error(NameError, /uninitialized constant (LittlePlugger::)?Plugins/)
    expect(LittlePlugger.default_plugin_module('process/status')).to eq(Process::Status)
  end
end

# EOF
