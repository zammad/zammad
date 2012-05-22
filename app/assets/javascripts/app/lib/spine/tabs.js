(function() {
  var $,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  if (typeof Spine === "undefined" || Spine === null) Spine = require('spine');

  $ = Spine.$;

  Spine.Tabs = (function(_super) {

    __extends(Tabs, _super);

    Tabs.prototype.events = {
      'click [data-name]': 'click'
    };

    function Tabs() {
      this.change = __bind(this.change, this);      Tabs.__super__.constructor.apply(this, arguments);
      this.bind('change', this.change);
    }

    Tabs.prototype.change = function(name) {
      if (!name) return;
      this.current = name;
      this.children().removeClass('active');
      return this.children("[data-name=" + this.current + "]").addClass('active');
    };

    Tabs.prototype.render = function() {
      this.change(this.current);
      if (!(this.children('.active').length || this.current)) {
        return this.children(':first').click();
      }
    };

    Tabs.prototype.children = function(sel) {
      return this.el.children(sel);
    };

    Tabs.prototype.click = function(e) {
      var name;
      name = $(e.currentTarget).attr('data-name');
      return this.trigger('change', name);
    };

    Tabs.prototype.connect = function(tabName, controller) {
      var _this = this;
      this.bind('change', function(name) {
        if (name === tabName) return controller.active();
      });
      return controller.bind('active', function() {
        return _this.change(tabName);
      });
    };

    return Tabs;

  })(Spine.Controller);

  if (typeof module !== "undefined" && module !== null) {
    module.exports = Spine.Tabs;
  }

}).call(this);
