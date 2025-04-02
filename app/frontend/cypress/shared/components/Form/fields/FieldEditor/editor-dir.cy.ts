// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { checkFormMatchesSnapshot } from '#cy/utils.ts'

import { mountEditor } from './utils.ts'

const rtlWord = 'مرحبا'
const ltrWord = 'hello'

const setDefaultDir = (dir: 'ltr' | 'rtl') => {
  document.documentElement.setAttribute('dir', dir)
}

describe('editor has correct dir when text local is different', () => {
  describe('when ltr is default', () => {
    beforeEach(() => setDefaultDir('ltr'))

    it('text is ltr', () => {
      mountEditor()

      cy.findByRole('textbox').type(ltrWord)
      cy.findByText(ltrWord).should('not.have.attr', 'dir')
      // click away so we don't have "|" in text field
      cy.get('body').click()
      checkFormMatchesSnapshot({ type: 'ltr is default' })
    })

    it('text is rtl', () => {
      mountEditor()

      cy.findByRole('textbox').type(rtlWord)
      cy.findByText(rtlWord).should('have.attr', 'dir', 'rtl')
      // click away so we don't have "|" in text field
      cy.get('body').click()
      checkFormMatchesSnapshot({ type: 'ltr is default' })
    })
  })

  describe('when rtl is default', () => {
    beforeEach(() => setDefaultDir('rtl'))

    it('text is ltr', () => {
      mountEditor()

      cy.findByRole('textbox').type(ltrWord)
      cy.findByText(ltrWord).should('have.attr', 'dir', 'ltr')
      // click away so we don't have "|" in text field
      cy.get('body').click()
      checkFormMatchesSnapshot({ type: 'rtl is default' })
    })

    it('text is rtl', () => {
      mountEditor()

      cy.findByRole('textbox').type(rtlWord)
      cy.findByText(rtlWord).should('not.have.attr', 'dir')
      // click away so we don't have "|" in text field
      cy.get('body').click()
      checkFormMatchesSnapshot({ type: 'rtl is default' })
    })
  })
})
