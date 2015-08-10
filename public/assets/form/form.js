(function ($) {

/*
  provides feedback form for zammad
*/

  var pluginName = 'zammad_form',
  defaults = {
    debug: false,
    loadCss: true,
  };

  function Plugin( element, options ) {
    this.element  = element;
    this.$element = $(element)

    this.options = $.extend( {}, defaults, options) ;

    this._defaults = defaults;
    this._name     = pluginName;

    this._endpoint_config = '/api/v1/form_config'
    this._script_location = '/assets/form/form.js'

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
    var _this = this,
      src = document.getElementById("zammad_form_script").src,
      endpoint_config = src.replace(this._script_location, this._endpoint_config)

    _this.log('init')

    if (_this.options.loadCss) {
      _this.loadCss('form.css')
    }

    _this.log('endpoint_config: ' + endpoint_config)

    // load config
    $.ajax({
      url: endpoint_config,
    }).done(function(data) {
      _this.log('config:', data)
      _this._config = data
      _this.render()
    }).fail(function() {
      alert('Faild to load form config!')
    });

    // bind form submit
    this.$element.on('submit', function (e) {
      e.preventDefault()
      _this.submit()
      return true
    })
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

    _this.log('submit form', _this.getParams())

    $.ajax({
      method: 'post',
      url: _this._config.endpoint,
      data: _this.getParams(),
    }).done(function(data) {
      _this.log('ok done', _this._config.endpoint)

      // removed errors
      _this.$element.find('.has-error').removeClass('has-error')

      // set errors
      if (data.errors) {
        $.each(data.errors, function( key, value ) {
          _this.$element.find('[name=' + key + ']').closest('.form-group').addClass('has-error')
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

    $.each( _this.$element.find('form').serializeArray(), function( index, item ) {
      params[item.name] = item.value
    })
    return params
  }

  // render form
  Plugin.prototype.render = function(e) {
    var form = $('<form class="zammad-form"></form>')
    $.each(this.attributes, function( index, value ) {
      var item = $('<div class="form-group"><label>' + value.display + '</label></div>')
      if (value.tag == 'input') {
        item.append('<input class="form-control" name="' + value.name + '" type="' + value.type + '" placeholder="' + value.placeholder + '">')
      }
      else if (value.tag == 'textarea') {
        item.append('<textarea class="form-control" name="' + value.name + '" placeholder="' + value.placeholder + '"></textarea>')
      }
      form.append(item)
    })
    form.append('<button type="submit">' + 'Submit' + '</button')
    this.$element.html(form)
    return form
  }

  // thanks
  Plugin.prototype.thanks = function(e) {
    var form = $('<div>Thank you for your inquery!</div>')
    this.$element.html(form)
    return form
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