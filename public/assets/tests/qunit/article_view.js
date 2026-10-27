// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

QUnit.module('Article view inline images', {
  beforeEach() {
    this.sandbox = sinon.createSandbox()
    this.sandbox.stub(App, 'WidgetAvatar')
    this.sandbox.stub(App, 'TicketZoomArticleActions')
    this.sandbox.stub(App.TicketArticle, 'contentAttachments').returns([])
    this.sandbox.stub(App, 'view').callsFake(name => {
      if (name === 'ticket_zoom/article_view') return params => params.article.html
      return () => ''
    })

    this.element = $('<div>')
    this.view = {
      Config: App.Config,
      el: this.element,
      $: selector => this.element.find(selector),
      html: html => this.element.html(html),
      getArticleTimeUnit: () => null,
      getArticleActivityType: () => null,
      timeAccountingDisplayUnit: () => 'minute',
      delay: () => {},
      setHighlighter: () => {},
      textBubbleImages: $(),
    }
  },
  afterEach() {
    this.element.remove()
    this.sandbox.restore()
  },
})

QUnit.test('measures skipped messages only when their content becomes visible', function(assert) {
  var skipped = true
  this.element[0].oncontentvisibilityautostatechange = null
  this.view.textBubbleContent = [{ checkVisibility: () => !skipped }]
  this.view.measureSeeMore = this.sandbox.spy()
  this.element.css({ width: '100px', height: '100px' }).appendTo(document.body)

  App.ArticleViewItem.prototype.setSeeMore.call(this.view)
  assert.notOk(this.view.shown, 'skipped content still needs its initial measurement')
  assert.notOk(this.view.measureSeeMore.called, 'measuring would force skipped content to render')

  skipped = false
  this.view.textBubbleImages = $()
  App.ArticleViewItem.prototype.setSeeMore.call(this.view)
  assert.ok(this.view.shown, 'visible content is measured')
  assert.ok(this.view.measureSeeMore.calledOnce, 'the initial measurement runs once')

  App.ArticleViewItem.prototype.setSeeMore.call(this.view)
  assert.ok(this.view.measureSeeMore.calledOnce, 'later visibility changes do not reset expansion')
})

QUnit.test('ignores articles without a message bubble', function(assert) {
  this.view.textBubbleContent = $()
  this.view.measureSeeMore = this.sandbox.spy()
  this.element.css({ width: '100px', height: '100px' }).appendTo(document.body)

  App.ArticleViewItem.prototype.setSeeMore.call(this.view)
  assert.notOk(this.view.measureSeeMore.called, 'system messages do not need a fold measurement')
})

QUnit.test('keeps measuring normally without the visibility APIs', function(assert) {
  this.view.el = { 0: {}, is: () => false }
  this.view.textBubbleContent = [{}]
  this.view.textBubbleImages = $()
  this.view.measureSeeMore = this.sandbox.spy()

  App.ArticleViewItem.prototype.setSeeMore.call(this.view)
  assert.ok(this.view.measureSeeMore.calledOnce, 'browsers without containment events keep the existing behavior')
})

QUnit.test('defers inline images while preserving their source and sizing', function(assert) {
  var image = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7'
  var article = {
    id: 1,
    ticket_id: 1,
    type: { name: 'email' },
    sender: { name: 'Customer' },
    preferences: {},
    content_type: 'text/html',
    body: '<p>Screenshot</p><img src="' + image + '" style="width: 400px; height: 300px">',
  }

  App.ArticleViewItem.prototype.render.call(this.view, article)

  var rendered = this.element.find('img')[0]
  assert.equal(rendered.loading, 'lazy', 'inline images do not all load when a ticket opens')
  assert.equal(rendered.src, image, 'the original image remains available')
  assert.equal(rendered.style.maxHeight, '300px', 'the original height remains a size limit')
  assert.equal(rendered.style.height, 'auto', 'images retain their aspect ratio')
  assert.equal(rendered.style.maxWidth, '100%', 'images fit within the message')
  assert.equal(this.element.find('p').text(), 'Screenshot', 'the message text is preserved')
})

QUnit.test('requests deferred images before printing', function(assert) {
  this.element.addClass('ticket-article-item').appendTo(document.body)
  this.element.html('<img loading="lazy" alt="Screenshot">')

  $(window).triggerHandler('beforeprint')

  assert.equal(this.element.find('img')[0].loading, 'eager', 'printing includes images that have not been scrolled into view')
})
