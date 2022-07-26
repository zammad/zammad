// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { mountEditor } from './utils'

describe('resizing image within editor', () => {
  it('can be resized', () => {
    mountEditor()
    cy.findByRole('textbox').click()
    cy.findByTestId('action-bar')
      .findByLabelText('Add image')
      .find('input[type="file"]')
      .selectFile(
        {
          contents: '.cypress/fixtures/example.png',
          fileName: 'example.png',
          mimeType: 'image/png',
          lastModified: Date.now(),
        },
        { force: true },
      )
    cy.findByRole('textbox').get('img:first').trigger('click')

    cy.get('.vdr-handle:last')
      .trigger('mousedown', { button: 0 })
      .trigger('mousemove', { pageX: 100, pageY: 100 })
      .trigger('mouseup', { button: 0 })
      .then(($item) => {
        cy.get('img').then(($img) => {
          const height = $img.height()
          const width = $img.width()
          expect(width).to.eq(83)
          expect(height).to.eq(83)
          return $item
        })
      })
      .trigger('mousedown', { button: 0 })
      .trigger('mousemove', { pageX: 600, pageY: 600 }) // call large number, beyoud max width/height
      .trigger('mouseup', { button: 0 })
      .then(() => {
        cy.get('img').then(($img) => {
          const height = $img.height()
          const width = $img.width()
          // this is their max width and height
          expect(width).to.eq(200)
          expect(height).to.eq(200)
        })
      })
  })
})
