require File.expand_path('../../lib/autodiscover.rb', __FILE__)
require 'minitest/autorun'
require "minitest/autorun"
require "mocha/mini_test"

TEST_DIR = File.dirname(__FILE__)

class MiniTest::Spec
  def load_sample(name)
    File.read("#{TEST_DIR}/fixtures/#{name}")
  end
end
