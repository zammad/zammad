// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//

//= require ./app/lib/core/jquery-2.2.1.js
//= require ./app/lib/core/jquery-ui-1.11.2.js
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
  for ( var name in object1 ) {
    if ( name in object2 ) {
      if ( _.isObject( object2[name] ) && !_.isArray( object2[name] ) ) {
        var diff = difference( object1[name], object2[name] );
        if ( !_.isEmpty( diff ) ) {
            changes[name] = diff;
        }
      } else if ( !_.isEqual( object1[name], object2[name] ) ) {
        changes[name] = object2[name];
      }
    }
  }
  return changes;
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
    acceptedInstances.push( 'Function' )
  }

  // check if item is accepted to get cloned
  if (itemType && !_.contains(acceptedInstances, itemType)) {
    console.log('no acceptedInstances', itemType, item)
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
        result[key] = clone( item[key], full )
      }
    }
  }
  // copy others
  else {
    result = item
  }
  return result
}

// taken from http://stackoverflow.com/questions/4459928/how-to-deep-clone-in-javascript
function clone2(item) {
    if (!item) { return item; } // null, undefined values check

    var types = [ Number, String, Boolean ],
        result;

    // normalizing primitives if someone did new String('aaa'), or new Number('444');
    types.forEach(function(type) {
        if (item instanceof type) {
            result = type( item );
        }
    });

    if (typeof result == "undefined") {
        if (Object.prototype.toString.call( item ) === "[object Array]") {
            result = [];
            item.forEach(function(child, index, array) {
                result[index] = clone( child );
            });
        } else if (typeof item == "object") {
            // testing that this is DOM
            if (item.nodeType && typeof item.cloneNode == "function") {
                var result = item.cloneNode( true );
            } else if (!item.prototype) { // check that this is a literal
                if (item instanceof Date) {
                    result = new Date(item);
                } else {
                    // it is an object literal
                    result = {};
                    for (var i in item) {
                        result[i] = clone( item[i] );
                    }
                }
            } else {
                // depending what you would like here,
                // just keep the reference, or create new object
                if (false && item.constructor) {
                    // would not advice to do that, reason? Read below
                    result = new item.constructor();
                } else {
                    result = item;
                }
            }
        } else {
            result = item;
        }
    }

    return result;
}

// taken from https://github.com/epeli/underscore.string/blob/master/underscored.js
function underscored (str) {
  return str.trim().replace(/([a-z\d])([A-Z]+)/g, '$1_$2').replace(/[-\s]+/g, '_').toLowerCase();
}

function toCamelCase (str) {
  return str
    .replace(/\s(.)/g, function($1) { return $1.toUpperCase(); })
    .replace(/\s/g, '')
    .replace(/^(.)/, function($1) { return $1.toUpperCase(); });
};

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

// start application
jQuery(function(){
  new App.Run();
});
