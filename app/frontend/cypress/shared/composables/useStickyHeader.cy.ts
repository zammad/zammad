// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mountComponent } from '#cy/utils.ts'
import { defineComponent, h, Fragment } from 'vue'

import { useStickyHeader } from '#shared/composables/useStickyHeader.ts'

const Component = defineComponent({
  setup() {
    const { headerElement, stickyStyles } = useStickyHeader()
    return () => {
      return h(Fragment, [
        h(
          'header',
          {
            ref: headerElement,
            class: 'bg-red',
            style: ['height: 30px;', stickyStyles.value.header],
          },
          'Header',
        ),
        h(
          'main',
          { style: ['height: 2000px;', stickyStyles.value.body] },
          'Content',
        ),
      ])
    }
  },
})

it('shows header when scroll is less than header height, and hides it afterwards', () => {
  mountComponent(Component)
  cy.findByRole('banner').should('be.visible')
  cy.scrollTo(0, 20)
  cy.findByRole('banner').should('be.visible')
  cy.scrollTo(0, 60)
  cy.findByRole('banner').should('not.be.visible')
})

it('shows header when scrolling up', () => {
  mountComponent(Component)
  cy.findByRole('banner').should('be.visible')
  cy.scrollTo(0, 60)
  cy.findByRole('banner').should('not.be.visible')
  cy.scrollTo(0, 20)
  cy.findByRole('banner').should('be.visible')
})
