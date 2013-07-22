// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//

//= require ./app/lib/core/jquery-1.10.2.min.js
//= require ./app/lib/core/jquery-ui-1.8.23.custom.min.js
//= require ./app/lib/core/underscore-1.5.1.js

//not_used= require_tree ./app/lib/spine
//= require ./app/lib/spine/spine.js
//= require ./app/lib/spine/ajax.js
//= require ./app/lib/spine/local.js
//= require ./app/lib/spine/route.js

//= require ./app/lib/flot/jquery.flot.js
//= require ./app/lib/flot/jquery.flot.selection.js

//not_used= require_tree ./app/lib/bootstrap
//= require ./app/lib/bootstrap/bootstrap-dropdown.js
//= require ./app/lib/bootstrap/bootstrap-tooltip.js
//= require ./app/lib/bootstrap/bootstrap-popover.js
//= require ./app/lib/bootstrap/bootstrap-modal.js
//= require ./app/lib/bootstrap/bootstrap-tab.js
//= require ./app/lib/bootstrap/bootstrap-transition.js
//= require ./app/lib/bootstrap/bootstrap-button.js
//= require ./app/lib/bootstrap/bootstrap-collapse.js

//= require_tree ./app/lib/base

//= require ./app/index.js.coffee

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

jQuery.event.special.remove = {
  remove: function(e) {
    if (e.handler) e.handler();
  }
};
