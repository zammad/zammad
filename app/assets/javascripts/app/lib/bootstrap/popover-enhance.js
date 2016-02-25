/* 
  
  Makes the popover stay when hovered over it

  from here http://jsfiddle.net/WojtekKruszewski/Zf3m7/22/

*/

var originalLeave = $.fn.popover.Constructor.prototype.leave;

$.fn.popover.Constructor.prototype.leave = function(obj){
  var self = obj instanceof this.constructor ?
    obj : $(obj.currentTarget)[this.type](this.getDelegateOptions()).data('bs.' + this.type)
  var container, timeout;

  originalLeave.call(this, obj);

  if(obj.currentTarget) {
    container = $('body .popover');
    timeout = self.timeout;
    container.one('mouseenter', function(){
      //We entered the actual popover – call off the dogs
      clearTimeout(timeout);
      //Let's monitor popover content instead
      container.one('mouseleave', function(){
        $.fn.popover.Constructor.prototype.leave.call(self, self);
      });
    })
  }
};

/*

  Add global 10px padding

*/

$.fn.popover.Constructor.DEFAULTS.viewport.padding = 10;

/* 

  Extend zammad popover template

  adds a popover-body around popover-title and popover-content 
  to make the popover scrollable without hiding the arrow

*/

$.fn.popover.Constructor.DEFAULTS.template = '<div class="popover" role="tooltip"><div class="arrow"></div><div class="popover-body"><h2 class="popover-title"></h2><div class="popover-content"></div></div></div>';

/*

  Add maxHeight to popovers

*/

var originalShow = $.fn.popover.Constructor.prototype.show;

$.fn.popover.Constructor.prototype.show = function(){
  originalShow.call(this);

  // improved error handling - no exeption if no $tip exists
  if (!this.$tip) {
    return
  }
  var maxHeight = $(this.options.viewport.selector).height() - 2 * this.options.viewport.padding;
  this.$tip.find('.popover-body').css('maxHeight', maxHeight);
}