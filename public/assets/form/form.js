(function ($) {

/*
  provides feedback form for zammad
*/

  var pluginName = 'zammad_form',
  defaults = {
    debug: false,
    noCSS: false,
    title: 'Zammad Form',
    messageHeadline: '',
    messageSubmit: 'Submit',
    messageThankYou: 'Thank you for your inquiry!',
  };

  function Plugin( element, options ) {
    this.element  = element;
    this.$element = $(element)

    this.options = $.extend( {}, defaults, options) ;

    this._defaults = defaults;
    this._name     = pluginName;

    this._endpoint_config = '/api/v1/form_config'
    this._endpoint_submit = '/api/v1/form_submit'
    this._script_location = '/assets/form/form.js'
    this._css_location    = '/assets/form/form.css'

    src = document.getElementById('zammad_form_script').src
    this.css_location = src.replace(this._script_location, this._css_location)
    this.endpoint_config = src.replace(this._script_location, this._endpoint_config)
    this.endpoint_submit = src.replace(this._script_location, this._endpoint_submit)

    this._config  = {}

    this.attributes = [
      {
        display: 'Name',
        name: 'name',
        tag: 'input',
        type: 'text',
        placeholder: 'Your Name',
      },
      {
        display: 'Email',
        name: 'email',
        tag: 'input',
        type: 'email',
        placeholder: 'Your Email',
      },
      {
        display: 'Message',
        name: 'body',
        tag: 'textarea',
        placeholder: 'Your Message...',
      },
    ]

    this.init();
  }


  Plugin.prototype.init = function () {
    var _this = this

    _this.log('init')

    if (!_this.options.noCSS) {
      _this.loadCss(_this.css_location)
    }

    _this.log('endpoint_config: ' + _this.endpoint_config)
    _this.log('endpoint_submit: ' + _this.endpoint_submit)

    // load config
    $.ajax({
      url: _this.endpoint_config,
    }).done(function(data) {
      _this.log('config:', data)
      _this._config = data
    }).fail(function() {
      alert('Faild to load form config!')
    });

    // show form
    if (!this.options.modal) {
      _this.render()
    }

    // bind form on call
    else {
      this.$element.on('click', function (e) {
        e.preventDefault()
        _this.render()
        return true
      })
    }
  }

  // load css
  Plugin.prototype.loadCss = function(filename) {
    if (document.createStyleSheet) {
      document.createStyleSheet(filename)
    }
    else {
      $('<link rel="stylesheet" type="text/css" href="' + filename + '" />').appendTo('head')
    }
  }

  // send
  Plugin.prototype.submit = function() {
    var _this = this

    $.ajax({
      method: 'post',
      url: _this.endpoint_submit,
      data: _this.getParams(),
    }).done(function(data) {

      // removed errors
      _this.$form.find('.has-error').removeClass('has-error')

      // set errors
      if (data.errors) {
        $.each(data.errors, function( key, value ) {
          _this.$form.find('[name=' + key + ']').closest('.form-group').addClass('has-error')
        })
        return
      }

      // ticket has been created
      _this.thanks()

    }).fail(function() {
      alert('Faild to submit form!')
    });
  }

  // get params
  Plugin.prototype.getParams = function() {
    var _this = this,
      params = {}

    $.each( _this.$form.serializeArray(), function( index, item ) {
      params[item.name] = item.value
    })

    if (!params.title) {
      params.title = this.options.title
    }

    _this.log('params', params)

    return params
  }

  Plugin.prototype.closeModal = function() {
    if (this.$modal) {
      this.$modal.remove()
    }
  }

  // render form
  Plugin.prototype.render = function(e) {
    var _this = this
    _this.closeModal()

    var element = '<div class="modal">\
      <div class="modal-backdrop js-close"></div>\
      <div class="modal-body">\
        <form class="zammad-form"></form>\
      </div>\
    </div>'

    if (!this.options.modal) {
      element = '<div><form class="zammad-form"></form></div>'
    }

    var $element = $(element)
    var $form = $element.find('form')
    if (this.options.messageHeadline && this.options.messageHeadline != '') {
      $form.append('<h2>' + this.options.messageHeadline + '</h2>')
    }
    $.each(this.attributes, function( index, value ) {
      var item = $('<div class="form-group"><label>' + value.display + '</label></div>')
      if (value.tag == 'input') {
        item.append('<input class="form-control" name="' + value.name + '" type="' + value.type + '" placeholder="' + value.placeholder + '">')
      }
      else if (value.tag == 'textarea') {
        item.append('<textarea class="form-control" name="' + value.name + '" placeholder="' + value.placeholder + '"></textarea>')
      }
      $form.append(item)
    })
    $form.append('<button type="submit" class="btn">' + this.options.messageSubmit + '</button')

    this.$modal = $element
    this.$form  = $form

    // bind on close
    $element.find('.js-close').on('click', function (e) {
      e.preventDefault()
      _this.closeModal()
      return true
    })

    // bind form submit
    $element.on('submit', function (e) {
      e.preventDefault()
      _this.submit()
      return true
    })

    // show form
    if (!this.options.modal) {
      _this.$element.html($element)
    }

    // append modal to body
    else {
      $('body').append($element)
    }

  }

  // thanks
  Plugin.prototype.thanks = function(e) {
    var thanks = $('<div class="js-thankyou">' + this.options.messageThankYou + '</div>')
    this.$form.html(thanks)
  }

  // log method
  Plugin.prototype.log = function() {
    if (this.options.debug) {
      console.log(this._name, arguments)
    }
  }

  $.fn[pluginName] = function ( options ) {
    return this.each(function () {
      if (!$.data(this, 'plugin_' + pluginName)) {
        $.data(this, 'plugin_' + pluginName,
        new Plugin( this, options ));
      }
    });
  }

}(jQuery));