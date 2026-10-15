// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// How the legacy interface rewrites links to other answers when an answer is inserted into a ticket
//   article: the counterpart of the answer link examples in
//   spec/graphql/gql/mutations/knowledge_base/answer/suggestion/content/transform_spec.rb.

window.onload = function() {
  App.Config.set('http_type', 'https')
  App.Config.set('fqdn', 'zammad.test')

  App.Locale.refresh([
    { id: 1, locale: 'en-us', alias: 'en', name: 'English (United States)' }
  ])

  App.KnowledgeBaseLocale.refresh([
    { id: 1, knowledge_base_id: 1, system_locale_id: 1, primary: true },
    { id: 2, knowledge_base_id: 2, system_locale_id: 1, primary: true }
  ])

  App.KnowledgeBase.refresh([
    { id: 1, active: true, iconset: 'FontAwesome', kb_locale_ids: [1], translation_ids: [] },
    { id: 2, active: false, iconset: 'FontAwesome', kb_locale_ids: [2], translation_ids: [] }
  ])

  App.KnowledgeBaseCategory.refresh([
    { id: 10, knowledge_base_id: 1, parent_id: null, position: 0, category_icon: 'f115' },
    { id: 20, knowledge_base_id: 2, parent_id: null, position: 0, category_icon: 'f115' }
  ])

  App.KnowledgeBaseAnswer.refresh([
    { id: 100, category_id: 10, position: 0, published_at: '2020-01-01T00:00:00.000Z' },
    { id: 101, category_id: 10, position: 1, internal_at: '2020-01-01T00:00:00.000Z' },
    { id: 102, category_id: 10, position: 2 },
    { id: 103, category_id: 10, position: 3, published_at: '2020-01-01T00:00:00.000Z', archived_at: '2020-01-02T00:00:00.000Z' },
    { id: 200, category_id: 20, position: 0, published_at: '2020-01-01T00:00:00.000Z' }
  ])

  App.KnowledgeBaseAnswerTranslation.refresh([
    { id: 1000, answer_id: 100, kb_locale_id: 1, title: 'Published answer' },
    { id: 1010, answer_id: 101, kb_locale_id: 1, title: 'Internal answer' },
    { id: 1020, answer_id: 102, kb_locale_id: 1, title: 'Draft answer' },
    { id: 1030, answer_id: 103, kb_locale_id: 1, title: 'Archived answer' },
    { id: 2000, answer_id: 200, kb_locale_id: 2, title: 'Published answer of an inactive knowledge base' }
  ])
}

var link = function(targetId, text) {
  return '<a href="/desktop/knowledge-base/locale/en-us/answer/1" data-target-type="knowledge-base-answer" data-target-id="' + targetId + '">' + text + '</a>'
}

var bodyWithPublicURLs = function(body) {
  return new App.KnowledgeBaseAnswerTranslationContent({ body: body }).bodyWithPublicURLs()
}

QUnit.test('kb answer links become ordinary links when an answer is inserted', assert => {
  var linkTo = function(href) {
    return '<p><a href="' + href + '">See also</a></p>'
  }

  assert.equal(
    bodyWithPublicURLs('<p>' + link(1000, 'See also') + '</p>'),
    linkTo('https://zammad.test/help/en-us/10/100'),
    'turns a link to a published answer into an ordinary one to its public page'
  )

  assert.equal(
    bodyWithPublicURLs('<p>' + link(1010, 'See also') + '</p>'),
    linkTo('https://zammad.test/#knowledge_base/1/locale/en-us/answer/101'),
    'turns a link to an internal answer into an ordinary absolute one to the answer in the agent interface'
  )

  assert.equal(
    bodyWithPublicURLs('<p>' + link(1020, 'See also') + '</p>'),
    linkTo('https://zammad.test/#knowledge_base/1/locale/en-us/answer/102'),
    'turns a link to a draft answer into an ordinary absolute one to the answer in the agent interface'
  )

  assert.equal(
    bodyWithPublicURLs('<p>' + link(1030, 'See also') + '</p>'),
    linkTo('https://zammad.test/#knowledge_base/1/locale/en-us/answer/103'),
    'turns a link to an archived answer into an ordinary absolute one to the answer in the agent interface'
  )

  assert.equal(
    bodyWithPublicURLs('<p>' + link(2000, 'See also') + '</p>'),
    linkTo('https://zammad.test/#knowledge_base/2/locale/en-us/answer/200'),
    'turns a link to an answer of an inactive knowledge base into an ordinary absolute one to the answer in the agent interface'
  )

  assert.equal(
    bodyWithPublicURLs('<p>' + link(9999, 'See also') + '</p>'),
    '<p>See also</p>',
    'replaces a link to a missing answer by its text'
  )

  assert.equal(
    bodyWithPublicURLs('<p>' + link(9999, '<strong>See</strong> also') + '</p>'),
    '<p><strong>See</strong> also</p>',
    'keeps markup inside a replaced link'
  )

  assert.equal(
    bodyWithPublicURLs('<p><a href="https://example.com">Example</a></p>'),
    '<p><a href="https://example.com">Example</a></p>',
    'leaves other links alone'
  )
})

QUnit.test('kb public address with a custom domain follows the configured scheme', assert => {
  var httpType      = App.Config.get('http_type')
  var knowledgeBase = App.KnowledgeBase.find(1)
  var kbLocale      = App.KnowledgeBaseLocale.find(1)

  knowledgeBase.custom_address = 'help.example.com'

  App.Config.set('http_type', 'https')

  assert.equal(knowledgeBase.publicBaseUrl(kbLocale), 'https://help.example.com/en-us')

  App.Config.set('http_type', 'http')

  assert.equal(knowledgeBase.publicBaseUrl(kbLocale), 'http://help.example.com/en-us')

  knowledgeBase.custom_address = 'help.example.com:443/support'

  assert.equal(knowledgeBase.publicBaseUrl(kbLocale), 'http://help.example.com/support/en-us', 'omits a port of either scheme default')

  knowledgeBase.custom_address = 'help.example.com:8443/support'

  assert.equal(knowledgeBase.publicBaseUrl(kbLocale), 'http://help.example.com:8443/support/en-us', 'keeps any other port')

  knowledgeBase.custom_address = null

  App.Config.set('http_type', httpType)
})
