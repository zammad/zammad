(function(){
  function Util() { }

  Util.generateIcon = function(iconName, iconset) {
    if(!iconset) {
      return '<svg class="icon icon-' + iconName + '"><use xlink:href="/' + document.documentElement.dataset.iconsUrl + '#icon-' + iconName + '"></use></svg>'
    }

    return '<i data-font="' + iconset + '">&#x' + iconName + '</i>'
  }

  Zammad.Util = Util;
})()
