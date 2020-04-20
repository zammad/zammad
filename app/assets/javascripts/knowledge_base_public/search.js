(function() {
  document.addEventListener('DOMContentLoaded', function(event) {
    var elem = document.querySelector('.js-search-input')
    KnowledgeBaseSearch.bindEvent(elem)
  });

  function KnowledgeBaseSearch() { }

  KnowledgeBaseSearch.lookup = function(query) {
    if(this.timeoutIdentifier) {
      clearTimeout(this.timeoutIdentifier)
    }

    this.clearContainer()

    var self = this
    this.timeoutIdentifier = setTimeout(function(e) { self.lookupAction(query) }, 300)
  }

  KnowledgeBaseSearch.lookupAction = function(query) {
    var params = {
      knowledge_base_id: document.querySelector('html').dataset.id,
      locale: document.querySelector('html').lang,
      query: query,
      flavor: 'public'
    }

    if(query === '') {
      return
    }

    var self = this

    fetch('/api/v1/knowledge_bases/search', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify(params)
    })
      .then(function(resp) { return resp.json() })
      .then(function(json) {
        var newElems

        if(json.details.length === 0) {
          newElems = [new SearchResultMessage({ text: self.container().dataset.emptyPlaceholder })]
        } else {
          newElems = json.details.map(function(elem) { return new SearchResultElement(elem)})
        }

        newElems.forEach(function(elem) { self.container().appendChild(elem.el) } )
      }).catch( function(error) {
        var elem = new SearchResultMessage({ text: error.message })
        self.container().appendChild(elem.el)
      })
  }

  KnowledgeBaseSearch.container = function() {
    return document.querySelector('.js-search-results')
  }

  KnowledgeBaseSearch.clearContainer = function() {
    var container = this.container()

    while (container.firstChild !== null) container.removeChild(container.firstChild);
  }

  KnowledgeBaseSearch.bindEvent = function(field) {
    field.addEventListener('input', function(e) { KnowledgeBaseSearch.lookup(field.value)})
  }

  function SearchResultElement(data) {
    this.el = document.createElement('li')

    this.render = function() {
      this.el.classList.add('result')
      this.el.innerHTML = this.constructor.template

      this.setTitle(data.title)
      this.setSubtitle(data.subtitle)
      this.setPreview(data.body)
      this.setURL(data.url)
      this.setIcon(data.icon, data.type)
    }

    this.setTitle = function(text) {
      this.el.querySelector('.result-title').innerHTML = text || ''
    }

    this.setSubtitle = function(text) {
      this.el.querySelector('.result-category').innerHTML = text || ''
    }

    this.setPreview = function(text) {
      this.el.querySelector('.result-preview').innerHTML = text || ''
    }

    this.setURL = function(url) {
      this.el.querySelector('a').href =  url || '#'
    }

    this.setIcon = function(iconName, type) {
      this.el.querySelector('.result-icon').innerHTML = this.generateIcon(iconName, type)
    }

    this.generateIcon = function(iconName, type) {
      switch(type) {
        case 'KnowledgeBase::Category::Translation':
          iconset = document.querySelector('html').dataset.iconset
          return Zammad.Util.generateIcon(iconName, iconset)
        default:
          return Zammad.Util.generateIcon(iconName)
      }
    }

    this.render()
  }

  SearchResultElement.template = '<a>' +
  '  <span class="result-icon"></span>' +
  '  <h3 class="result-title"></h3>' +
  '  <div class="result-subtitle">' +
  '    <span class="result-category"></span>' +
  '    <span class="result-preview"></span>' +
  ' </div>' +
  '</a>';

  function SearchResultMessage(data) {
    this.el = document.createElement('li')
    this.el.classList.add('search-message')
    this.el.textContent = data.text;
  }
}())
