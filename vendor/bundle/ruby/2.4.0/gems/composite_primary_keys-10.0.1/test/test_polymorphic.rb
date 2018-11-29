require File.expand_path('../abstract_unit', __FILE__)

class TestPolymorphic < ActiveSupport::TestCase
  fixtures :users, :employees, :comments, :hacks, :articles, :readings

  def test_polymorphic_has_many
    comments = Hack.find(7).comments
    assert_equal 7, comments[0].person_id
  end

  def test_polymorphic_has_one
    first_comment = Hack.find(7).first_comment
    assert_equal 7, first_comment.person_id
  end

  def test_has_many_through
    assert_equal(2, Article.count, 'Baseline sanity check')
    user = users(:santiago)
    article_names = user.articles.collect { |a| a.name }.sort
    assert_equal ['Article One', 'Article Two'], article_names
  end

  def test_polymorphic_has_many_through
    user = users(:santiago)
    assert_equal(['andrew'], user.hacks.collect { |a| a.name }.sort)
  end
end
