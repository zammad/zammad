require File.expand_path('../abstract_unit', __FILE__)

class TestDumpable < ActiveSupport::TestCase
  fixtures :articles, :readings, :users

  def test_marshal_with_simple_preload
    articles = Article.preload(:readings).where(id: 1).to_a
    assert_equal(Marshal.load(Marshal.dump(articles)), articles)
  end

  def test_marshal_with_comples_preload
    articles = Article.preload({ readings: :user }).where(id: 1).to_a
    assert_equal(Marshal.load(Marshal.dump(articles)), articles)
  end
end
