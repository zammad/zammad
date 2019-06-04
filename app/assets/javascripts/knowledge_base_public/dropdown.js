(function() {
  document.addEventListener('DOMContentLoaded', function(event) {
    document
      .querySelector('[data-toggle="dropdown"]')
      .addEventListener('click', toggleDropdown)

    document
      .querySelector('.dropdown-menu')
      .addEventListener('click', function(event) { event.stopPropagation() })
  })

  function toggleDropdown(event){
    event.stopPropagation()
    event.preventDefault()

    var elem = document.querySelector('.dropdown-menu')
    var open = elem.classList.toggle('is-open')

    if(elem.setAttribute) // not supported by IE11
      elem.setAttribute('aria-expanded', open ? 'true' : 'false')

    if(open) {
      window.addEventListener('click', toggleDropdown)
    } else {
      window.removeEventListener('click', toggleDropdown)
    }
  }
}())
