// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//

//= require ./app/lib/core/jquery-2.2.1.js
//= require ./app/lib/core/jquery-ui-1.11.4.js
//= require ./app/lib/core/underscore-1.8.3.js

//= require ./app/lib/animations/velocity.min.js
//= require ./app/lib/animations/velocity.ui.js

//not_used= require_tree ./app/lib/spine
//= require ./app/lib/spine/spine.coffee
//= require ./app/lib/spine/ajax.coffee
//= require ./app/lib/spine/local.coffee
//= require ./app/lib/spine/route.coffee

//= require ./app/lib/flot/jquery.flot.js
//= require ./app/lib/flot/jquery.flot.selection.js

//not_used= require_tree ./app/lib/bootstrap
//= require ./app/lib/bootstrap/dropdown.js
//= require ./app/lib/bootstrap/tooltip.js
//= require ./app/lib/bootstrap/popover.js
//= require ./app/lib/bootstrap/popover-enhance.js

// modified by Felix Jan-2014
//= require ./app/lib/bootstrap/modal.js

//= require ./app/lib/bootstrap/tab.js
//= require ./app/lib/bootstrap/transition.js
//= require ./app/lib/bootstrap/button.js
//= require ./app/lib/bootstrap/collapse.js
//= require ./app/lib/bootstrap/bootstrap-timepicker.js
//= require ./app/lib/bootstrap/bootstrap-datepicker.js

//= require ./app/lib/rangy/rangy-core.js
//= require ./app/lib/rangy/rangy-classapplier.js
//= require ./app/lib/rangy/rangy-textrange.js
//= require ./app/lib/rangy/rangy-highlighter.js

//= require_tree ./app/lib/base

//= require ./app/index.coffee

// IE8 workaround for missing console.log
if (!window.console) {
  window.console = {}
}
if (!console.log) {
  console.log = function(){}
}

function escapeRegExp(str) {
  return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
}

Date.prototype.getWeek = function() {
  var onejan = new Date(this.getFullYear(),0,1);
  return Math.ceil((((this - onejan) / 86400000) + onejan.getDay()+1)/7);
}

function difference(object1, object2) {
  var changes = {};
  for (var name in object1) {
    if (name in object2) {
      if (_.isObject(object2[name]) && !_.isArray(object2[name])) {
        var diff = difference(object1[name], object2[name]);
        if (!_.isEmpty(diff)) {
            changes[name] = diff;
        }
      } else if (!_.isEqual(object1[name], object2[name])) {
        changes[name] = object2[name];
      }
    }
  }
  return changes;
}

// returns the byte length of an utf8 string
// taken from http://stackoverflow.com/questions/5515869/string-length-in-bytes-in-javascript
function byteLength(str) {
  var s = str.length
  for (var i=str.length-1; i>=0; i--) {
    var code = str.charCodeAt(i)
    if (code > 0x7f && code <= 0x7ff) s++
    else if (code > 0x7ff && code <= 0xffff) s+=2
    if (code >= 0xDC00 && code <= 0xDFFF) i-- //trail surrogate
  }
  return s
}

// clone, just data, no instances of objects
function clone(item, full) {

  // just return/clone false conditions
  if (!item) { return item }

  var itemType = item.constructor.name

  // IE behavior // doesn't know item.constructor.name, detect it by underscore
  if (itemType === undefined) {
    if (_.isArray(item)) {
      itemType = 'Array'
    }
    else if (_.isNumber(item)) {
      itemType = 'Number'
    }
    else if (_.isString(item)) {
      itemType = 'String'
    }
    else if (_.isBoolean(item)) {
      itemType = 'Boolean'
    }
    else if (_.isFunction(item)) {
      itemType = 'Function'
    }
    else if (_.isObject(item)) {
      itemType = 'Object'
    }
  }

  // ignore certain objects
  var acceptedInstances = [ 'Object', 'Number', 'String', 'Boolean', 'Array' ]
  if (full) {
    acceptedInstances.push('Function')
  }

  // check if item is accepted to get cloned
  if (itemType && !_.contains(acceptedInstances, itemType)) {
    console.log('no acceptedInstances', itemType, item)
    console.trace()
    return
  }

  // copy array
  var result;
  if (itemType == 'Array')  {
    result = []
    item.forEach(function(child, index, array) {
      result[index] = clone( child, full )
    });
  }

  // copy function
  else if (itemType == 'Function') {
    result = item.bind({})
  }

  // copy object
  else if (itemType == 'Object') {
    result = {}
    for(var key in item) {
      if (item.hasOwnProperty(key)) {
        result[key] = clone(item[key], full)
      }
    }
  }
  // copy others
  else {
    result = item
  }
  return result
}

// taken from https://github.com/epeli/underscore.string/blob/master/underscored.js
function underscored(str) {
  return str.trim().replace(/([a-z\d])([A-Z]+)/g, '$1_$2').replace(/[-\s]+/g, '_').toLowerCase();
}

function toCamelCase(str) {
  return str
    .replace(/\s(.)/g, function($1) { return $1.toUpperCase(); })
    .replace(/\s/g, '')
    .replace(/^(.)/, function($1) { return $1.toUpperCase(); });
};

function isRetina(){
  if (window.matchMedia) {
    var mq = window.matchMedia("only screen and (min--moz-device-pixel-ratio: 1.3), only screen and (-o-min-device-pixel-ratio: 2.6/2), only screen and (-webkit-min-device-pixel-ratio: 1.3), only screen  and (min-device-pixel-ratio: 1.3), only screen and (min-resolution: 1.3dppx)");
    return (mq && mq.matches || (window.devicePixelRatio > 1));
  }
}

jQuery.event.special.remove = {
  remove: function(e) {
    if (e.handler) e.handler();
  }
};

// checkbox-replacement helper
// native checkbox focus behaviour is the following:
// tab to checkbox: :focus state and focus outline
// click on checkbox: :focus state but no focus outline
$('body').on('click', '.checkbox-replacement, .radio-replacement', function(event){
  $(event.currentTarget).find('input').addClass('is-active')
});
$('body').on('blur', '.checkbox-replacement input, .radio-replacement input', function(){
  $(this).removeClass('is-active')
});

// remove attributes by regex
// http://stackoverflow.com/questions/8968767/remove-multiple-html5-data-attributes-with-jquery
jQuery.fn.removeAttrs = function(regex) {
  return this.each(function() {
    var $this = $(this),
      names = [];
    $.each(this.attributes, function(i, attr) {
      if (attr && attr.specified && regex.test(attr.name)) {
        $this.removeAttr(attr.name);
      }
    });
  });
};

// based on jquery serializeArray
// changes
// - set type based on data('field-type')
// - also catch [disabled] params
jQuery.fn.extend( {
  serializeArrayWithType: function() {
    var r20 = /%20/g,
      rbracket = /\[\]$/,
      rCRLF = /\r?\n/g,
      rsubmitterTypes = /^(?:submit|button|image|reset|file)$/i,
      rsubmittable = /^(?:input|select|textarea|keygen)/i;
    var rcheckableType = ( /^(?:checkbox|radio)$/i );
    return this.map( function() {

      // We dont use jQuery.prop( this, "elements" ); here anymore
      // because it did not work out for IE 11
      var elements = $(this).find('*').filter(':input');
      return elements ? jQuery.makeArray( elements ) : this;
    } )
    .filter( function() {
      var type = this.type;

      return this.name &&
        rsubmittable.test( this.nodeName ) && !rsubmitterTypes.test( type ) &&
        ( this.checked || !rcheckableType.test( type ) );
    } )
    .map( function( i, elem ) {
      var $elem = jQuery( this );
      var val = $elem.val();
      var type = $elem.data('field-type');

      var result;
      if ( val == null ) {

        // be sure that also null values are transfered
        // https://github.com/zammad/zammad/issues/944
        if ( $elem.prop('multiple') ) {
          result = { name: elem.name, value: null, type: type };
        }
        else {
          result = null
        }
      }
      else if ( jQuery.isArray( val ) ) {
        result = jQuery.map( val, function( val ) {
          return { name: elem.name, value: val.replace( rCRLF, "\r\n" ), type: type };
        } );
      }
      else {
        result = { name: elem.name, value: val.replace( rCRLF, "\r\n" ), type: type };
      }
      return result;
    } ).get();
  }
} );

// start application
jQuery(function(){
  new App.Run();
});
