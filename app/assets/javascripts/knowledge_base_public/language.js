(function() {
  function LanguageBannerElement(targetLanguage) {
    this.el = document.createElement('div')

    this.render = function() {
      this.el.innerHTML = this.constructor.template
      this.el.querySelector('a').href = this.itemPath() || this.kbPath()
      this.el.querySelector('.close').addEventListener('click', this.close.bind(this))
    }

    this.kbPath = function() {
      var html = document.querySelector('html')
      return html.dataset.basePath.replace(encodeURIComponent('{locale}'), targetLanguage)
    }

    this.close = function() {
      this.el.remove()
    }

    this.itemPath = function() {
      var item = document.querySelector('main')
      if(!item) { return null }

      var path = item.dataset.basePath
      var object_locales = item.dataset.availableLocales
      if(!path || !object_locales) { return null }

      object_locales = object_locales.split(',')
      if(!LanguageDetector.includes(object_locales, targetLanguage)) { return null }

      path = path.replace(encodeURIComponent('{locale}'), targetLanguage)

      return path
    }

    this.render()
  }

  LanguageBannerElement.template = '<div class="language-banner">' +
  Zammad.Util.generateIcon('mood-supergood') +
  '  <p class="language-banner-text">' +
  '    The Knowledge Base is available in your language <a class="button button--small">activate</a>' +
  '  </p>' +
  '  <div class="spacer"></div>' +
  '  <div class="close">' +
  Zammad.Util.generateIcon('diagonal-cross') +
  '  </div>' +
  '</div>';

  function LanguageDetector() { }

  LanguageDetector.html = function() { return document.querySelector('html') }

  LanguageDetector.document_languages = function() {
    return this.html().dataset.availableLocales.split(',')
  }

  LanguageDetector.user_languages = function() {
    var languages = navigator.userLanguage || navigator.languages || navigator.language

    if(Array.isArray(languages)) {
      return languages
    } else if(languages) {
      return [languages]
    } else {
      return []
    }
  }

  LanguageDetector.is_current = function(locale) {
    return this.extract_language(this.html().lang) === this.extract_language(locale)
  }

  LanguageDetector.includes = function(array, item) {
    item = this.extract_language(item)

    return array.filter(function(locale) { return this.extract_language(locale) === item}, this)[0] !== undefined
  }

  LanguageDetector.offer_language = function() {
    if(this.includes(this.user_languages(), this.html().lang)) {
      return null;
    }

    return this.document_languages().filter(function(lang) { return this.includes(this.user_languages(), lang)}, this)[0]
  }

  LanguageDetector.extract_language = function(value) {
    return value.split('-')[0]
  }

  LanguageDetector.checkIfBetterLanguageAvailable = function() {
    var another_language = this.offer_language()

    if(!another_language) { return }

    this.show(another_language)
  }

  LanguageDetector.show = function(lang) {
    var elem = new LanguageBannerElement(lang)
    document.querySelector('.js-wrapper').prepend(elem.el)
  }

  LanguageDetector.checkIfBetterLanguageAvailable()
}())
