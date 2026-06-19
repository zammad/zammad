// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

(function() {
  document.addEventListener('DOMContentLoaded', function() {
    document
      .querySelectorAll('.article-content img')
      .forEach(bindImagePreview)
  })

  function bindImagePreview(image) {
    if (image.closest('a')) {
      return
    }

    image.classList.add('is-previewable')
    image.addEventListener('click', function(event) {
      event.preventDefault()
      event.stopPropagation()

      openImagePreview(image)
    })
  }

  function openImagePreview(sourceImage) {
    var previouslyFocused = document.activeElement
    var preview = document.createElement('div')
    var controls = document.createElement('div')
    var closeButton = document.createElement('button')
    var downloadLink = document.createElement('a')
    var image = document.createElement('img')

    preview.className = 'kb-image-preview'
    preview.setAttribute('role', 'dialog')
    preview.setAttribute('aria-modal', 'true')
    preview.setAttribute('tabindex', '-1')

    controls.className = 'kb-image-preview-controls'

    closeButton.className = 'button button--small'
    closeButton.type = 'button'
    closeButton.textContent = 'Close'

    downloadLink.className = 'button button--small'
    downloadLink.href = sourceImage.src
    downloadLink.target = '_blank'
    downloadLink.rel = 'noopener noreferrer'
    downloadLink.textContent = 'Download'

    image.className = 'kb-image-preview-image'
    image.src = sourceImage.src
    image.alt = sourceImage.alt || ''

    controls.appendChild(closeButton)
    controls.appendChild(downloadLink)
    preview.appendChild(controls)
    preview.appendChild(image)
    document.body.appendChild(preview)
    document.body.classList.add('kb-image-preview-open')
    preview.focus()

    closeButton.addEventListener('click', close)
    preview.addEventListener('click', closeFromBackdrop)
    document.addEventListener('keydown', handleKeydown)

    function closeFromBackdrop(event) {
      if (event.target === preview) {
        close()
      }
    }

    function handleKeydown(event) {
      if (event.key === 'Escape') {
        close()
      }
    }

    function close() {
      document.removeEventListener('keydown', handleKeydown)
      document.body.classList.remove('kb-image-preview-open')
      preview.remove()

      if (previouslyFocused && previouslyFocused.focus) {
        previouslyFocused.focus()
      }
    }
  }
}())
