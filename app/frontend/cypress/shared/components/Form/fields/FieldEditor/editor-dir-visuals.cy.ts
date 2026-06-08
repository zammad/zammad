// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { checkFormMatchesSnapshot } from '#cy/utils.ts'

import { mountEditor } from './utils.ts'

const rtlWord = 'مرحبا'
const ltrWord = 'hello'

const setDefaultDir = (dir: 'ltr' | 'rtl') => {
  document.documentElement.setAttribute('dir', dir)
}

describe('editor handles dir automatically', () => {
  describe('when ltr is default', () => {
    beforeEach(() => setDefaultDir('ltr'))

    it('text is ltr', () => {
      mountEditor()

      cy.findByRole('textbox').type(ltrWord)
      cy.findByText(ltrWord).should('have.attr', 'dir')
      // lose focus to hide the text cursor
      cy.findByRole('textbox').blur()
      checkFormMatchesSnapshot({ type: 'ltr is default' })
    })

    it('text is rtl', () => {
      mountEditor()

      cy.findByRole('textbox').type(rtlWord)
      cy.findByText(rtlWord).should('have.attr', 'dir', 'auto')
      // lose focus to hide the text cursor
      cy.findByRole('textbox').blur()
      checkFormMatchesSnapshot({ type: 'ltr is default' })
    })
  })

  describe('when rtl is default', () => {
    beforeEach(() => setDefaultDir('rtl'))

    it('text is ltr', () => {
      mountEditor()

      cy.findByRole('textbox').type(ltrWord)
      cy.findByText(ltrWord).should('have.attr', 'dir', 'auto')
      // lose focus to hide the text cursor
      cy.findByRole('textbox').blur()
      checkFormMatchesSnapshot({ type: 'rtl is default' })
    })

    it('text is rtl', () => {
      mountEditor()

      cy.findByRole('textbox').type(rtlWord)
      cy.findByText(rtlWord).should('have.attr', 'dir')
      // lose focus to hide the text cursor
      cy.findByRole('textbox').blur()
      checkFormMatchesSnapshot({ type: 'rtl is default' })
    })
  })
})
