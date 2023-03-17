(function() {
  document.addEventListener('DOMContentLoaded', function(event) {
    document
      .querySelectorAll('[data-toggle="dropdown"]')
      .forEach(function(elem) {
        elem.addEventListener('click', toggleDropdown)
      })

    document
      .querySelectorAll('.dropdown-menu')
      .forEach(function(elem) {
        elem.addEventListener('click', function(event) { event.stopPropagation() })
      })
  })

  function toggleDropdown(event){
    event.stopPropagation()
    event.preventDefault()

    var elem = event.target.closest('div').querySelector('.dropdown-menu')
    var open = elem.classList.toggle('is-open')

    if(elem.setAttribute) // not supported by IE11
      elem.setAttribute('aria-expanded', open ? 'true' : 'false')

    if(open) {
      window.addEventListener('click', globalCloseDropdown)
    } else {
      window.removeEventListener('click', globalCloseDropdown)
    }
  }

  function globalCloseDropdown(event){
    event.stopPropagation()
    event.preventDefault()

    event
      .target
      .querySelectorAll('.dropdown-menu.is-open')
      .forEach(function(elem) {
        elem.classList.remove('is-open')
        elem.setAttribute('aria-expanded', 'false')
      })

    window.removeEventListener('click', globalCloseDropdown)
  }
}())
