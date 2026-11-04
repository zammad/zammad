// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

QUnit.module('Article view long messages', {
  beforeEach() {
    this.sandbox = sinon.createSandbox()
    this.sandbox.stub(App, 'WidgetAvatar')
    this.sandbox.stub(App, 'TicketZoomArticleActions')
    this.sandbox.stub(App.TicketArticle, 'contentAttachments').returns([])
    this.sandbox.stub(App, 'view').callsFake(name => {
      if (name === 'ticket_zoom/article_view') {
        return params => `<div class="textBubble-content"><div class="richtext-content">${params.article.html}</div><div class="textBubble-overflowContainer hide"></div></div>`
      }
      return () => ''
    })

    this.element = $('<div>')
    this.view = Object.assign(Object.create(App.ArticleViewItem.prototype), {
      Config: App.Config,
      el: this.element,
      $: selector => this.element.find(selector),
      html: html => {
        this.element.html(html)
        this.view.refreshElements()
      },
      refreshElements: () => {
        this.view.textBubbleContent = this.element.find('.textBubble-content')
        this.view.textBubbleImages = this.element.find('.textBubble-content img')
        this.view.textBubbleOverflowContainer = this.element.find('.textBubble-overflowContainer')
      },
      getArticleTimeUnit: () => null,
      getArticleActivityType: () => null,
      timeAccountingDisplayUnit: () => 'minute',
      delay: () => {},
      setHighlighter: () => {},
      measureSeeMore: () => {},
      seeMoreOpen: false,
    })

    this.article = body => ({
      id: 1,
      ticket_id: 1,
      type: { name: 'email' },
      sender: { name: 'Customer' },
      preferences: {},
      content_type: 'text/html',
      body,
    })
    this.longBody = '<p>Latest reply</p><div>' + '<p>quoted</p>'.repeat(1000) + '</div>'
    this.bodyElements = () => this.element.find('.richtext-content *').length
  },
  afterEach() {
    this.element.remove()
    this.sandbox.restore()
  },
})

QUnit.test('keeps a short message whole', function(assert) {
  App.ArticleViewItem.prototype.render.call(this.view, this.article('<p>one</p><p>two</p>'))

  assert.equal(this.bodyElements(), 2, 'nothing is removed')
  assert.notOk(this.view.fullBody, 'nothing is held back')
})

QUnit.test('renders only the start of a long message until it is asked for', function(assert) {
  App.ArticleViewItem.prototype.render.call(this.view, this.article(this.longBody))

  var limit = App.ArticleViewItem.SEE_MORE_MAX_ELEMENTS
  assert.ok(this.bodyElements() < limit, 'the quoted history stays out of the page')
  assert.equal(this.element.find('.richtext-content p').first().text(), 'Latest reply', 'the newest text is kept')

  App.ArticleViewItem.prototype.showFullBody.call(this.view)

  assert.equal(this.bodyElements(), 1002, 'the whole message is restored')
  assert.notOk(this.view.fullBody, 'the message is only restored once')
  assert.ok(this.element.find('.textBubble-content').attr('data-height'), 'the expanded height is known')
})

QUnit.test('offers See more for a truncated message shorter than the fold', function(assert) {
  this.view.measureSeeMore = App.ArticleViewItem.prototype.measureSeeMore
  this.view.seeMoreOpen = false
  this.element.appendTo(document.body)

  App.ArticleViewItem.prototype.render.call(this.view, this.article('<span></span>'.repeat(1000)))
  this.view.measureSeeMore()

  assert.notOk(this.element.find('.textBubble-overflowContainer').hasClass('hide'), 'the rest of the message stays reachable')
})

QUnit.test('keeps highlighted messages whole', function(assert) {
  var article = this.article(this.longBody)
  article.preferences.highlight = 'type:textContent|0$5$1$highlight-Yellow$'

  App.ArticleViewItem.prototype.render.call(this.view, article)

  assert.equal(this.bodyElements(), 1002, 'highlights are stored as offsets into the whole message')
})

QUnit.test('keeps an expanded message whole when it renders again', function(assert) {
  this.view.seeMoreOpen = true

  App.ArticleViewItem.prototype.render.call(this.view, this.article(this.longBody))

  assert.equal(this.bodyElements(), 1002, 'an open message does not lose its text')
})

QUnit.test('keeps an expanded message open while its images load', function(assert) {
  this.view.measureSeeMore = App.ArticleViewItem.prototype.measureSeeMore
  this.element.appendTo(document.body)
  App.ArticleViewItem.prototype.render.call(this.view, this.article('<p>Reply</p><span class="js-signatureMarker"></span><p>Signature</p><div style="height: 2000px"></div>'))

  this.view.seeMoreOpen = true
  this.view.measureSeeMore()

  assert.equal(this.element.find('.textBubble-content')[0].style.height, 'auto', 'a late image does not fold the message')
})

QUnit.test('defers inline images while preserving their source and sizing', function(assert) {
  var image = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7'

  App.ArticleViewItem.prototype.render.call(this.view, this.article('<p>Screenshot</p><img src="' + image + '" style="width: 400px; height: 300px">'))

  var rendered = this.element.find('img')[0]
  assert.equal(rendered.loading, 'lazy', 'inline images do not all load when a ticket opens')
  assert.equal(rendered.src, image, 'the original image remains available')
  assert.equal(rendered.style.maxHeight, '300px', 'the original height remains a size limit')
  assert.equal(rendered.style.height, 'auto', 'images retain their aspect ratio')
  assert.equal(rendered.style.maxWidth, '100%', 'images fit within the message')
  assert.equal(this.element.find('p').text(), 'Screenshot', 'the message text is preserved')
})

QUnit.test('prepares every visible message for printing', function(assert) {
  this.element.addClass('ticket-article-item').appendTo(document.body)
  this.element.on('showFullBody', () => this.element.find('img').attr('loading', 'lazy').addClass('restored'))
  this.element.html('<img loading="lazy" alt="Screenshot">')

  $(window).triggerHandler('beforeprint')

  var image = this.element.find('img')[0]
  assert.ok($(image).hasClass('restored'), 'printing includes the whole message')
  assert.equal(image.loading, 'eager', 'printing includes images that have not been scrolled into view')
})
