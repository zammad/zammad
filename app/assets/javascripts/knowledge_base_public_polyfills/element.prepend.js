(function(){
  if(Element.prototype.prepend) return

  Element.prototype.prepend = function(newNode) {
    this.insertBefore(newNode, this.firstChild)
  }
}())
