$LOAD_PATH.unshift File.expand_path('../lib', File.dirname(__FILE__))
require 'inflection'
require 'minitest/autorun'

def examples(filename, &block)
  File.open(File.expand_path('inflection', File.dirname(__FILE__))).each_line do |line|
    block.call(line.split)
  end
end

describe ::Inflection do
  describe "convert singular <=> plural" do
    examples('inflection') do |singular, plural|
      it "should convert from %s to %s" % [singular, plural] do
        ::Inflection.plural(singular).must_equal plural
      end
      it "and back" do
        ::Inflection.singular(plural).must_equal singular
      end
    end
  end

  describe "convert plural => singular" do
    examples('injective') do |singular, plural|
      it "should convert from %s to %s" % [singular, plural] do
        ::Inflection.singular(plural).must_equal singular
      end
    end
  end
end
