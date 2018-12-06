require 'test_helper'

class SearchIndexBackendTest < ActiveSupport::TestCase
  test 'query extension keys are normalized to symbols' do
    query_strings = SearchIndexBackend.build_query('', query_extension: { 'bool' => { 'filter' => { 'term' => { 'a' => 'b' } } } })
    query_symbols = SearchIndexBackend.build_query('', query_extension: { bool: { filter: { term: { a: 'b' } } } })

    assert_equal query_strings, query_symbols
    assert_not_nil query_strings.dig(:query, :bool, :filter, :term, :a)
  end

  test 'search with ES off never returns nil in array' do
    index_one   = SearchIndexBackend.search('preferences.notification_sound.enabled:*', 'User', limit: 3000)
    index_multi = SearchIndexBackend.search('preferences.notification_sound.enabled:*', %w[User Organization], limit: 3000)

    assert_nil index_one
    assert index_multi.empty?
  end

  test 'simple_query_append_wildcard correctly modifies simple queries' do
    def clean_queries(query_string)
      query_string.each_line
                  .map(&:strip)
                  .reject(&:empty?)
                  .map { |x| x.split('#')[0] }
    end

    # Examples of complex queries from https://docs.zammad.org/en/latest/general-search.html
    complex_queries = clean_queries %(
        title:”some words with spaces” # exact phrase / without quotation marks ” an AND search for the words will be performed (in Zammad 1.5 and lower an OR search will be performed)
        title:”some wor*” # exact phrase beginning with “some wor*” will be searched
        created_at:[2017-01-01 TO 2017-12-31] # a time range
        created_at:>now-1h # created within last hour
        state:new OR state:open
        (state:new OR state:open) OR priority:”3 normal”
        (state:new OR state:open) AND customer.lastname:smith
        state:(new OR open) AND title:(full text search) # state: new OR open & title: full OR text OR search
        tags: “some tag”
        owner.email: “bod@example.com” AND state: (new OR open OR pending*) # show all open tickets of a certain agent
        state:closed AND _missing_:tag # all closed objects without tags
        article_count: [1 TO 5] # tickets with 1 to 5 articles
        article_count: [10 TO *] # tickets with 10 or more articles
        article.from: bob # also article.from can be used
        article.body: heat~ # using the fuzzy operator will also find terms that are similar, in this case also “head”
        article.body: /joh?n(ath[oa]n)/ # using regular expressions
        user:M
        user:Max
        user:Max.
        user:Max*
        organization:A_B
        organization:A_B*
        user: M
        user: Max
        user: Max.
        user: Max*
        organization: A_B
        organization: A_B*
        id:123
        number:123
        id:"123"
        number:"123"
    )

    simple_queries = clean_queries %(
        M

        Max
        Max. # dot and underscore are acceptable characters in simple queries
        A_
        A_B
        äöü
        123
        *ax  # wildcards are allowed in simple queries
        Max*
        M*x
        M?x
        test@example.com
        test@example.
        test@example
        test@
    )

    complex_queries.each do |query|
      result_query = SearchIndexBackend.append_wildcard_to_simple_query(query)
      # Verify that the result query is still the same as the input query
      assert_equal(query, result_query)
    end

    simple_queries.each do |query|
      result_query = SearchIndexBackend.append_wildcard_to_simple_query(query)
      # Verify that * is correctly appended to simple queries
      assert_equal(query + '*', result_query)
    end
  end
end
