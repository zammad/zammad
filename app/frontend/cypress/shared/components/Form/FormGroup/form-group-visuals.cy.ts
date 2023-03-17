// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

// To update snapshots, run `yarn cypress:snapshots`
// DO NOT update snapshots, when running with --open flag (Cypress GUI)

import { checkFormMatchesSnapshot, mountComponent } from '@cy/utils'
import { h } from 'vue'
import Form from '@shared/components/Form/Form.vue'
import DynamicInitializer from '@shared/components/DynamicInitializer/DynamicInitializer.vue'

describe('grouping form fields', () => {
  it('renders basic group', () => {
    const props = {
      schema: [
        {
          isLayout: true,
          component: 'FormGroup',
          children: [
            {
              type: 'text',
              required: true,
              name: 'text',
              label: 'Text',
            },
            {
              type: 'tel',
              props: { link: '/' },
              name: 'tel',
              label: 'Tel',
            },
            {
              type: 'textarea',
              name: 'textarea',
              label: 'Textarea',
            },
            {
              type: 'date',
              name: 'some_input_2',
              label: 'Date 2',
            },
            {
              type: 'tags',
              name: 'tags',
              label: 'Tags',
              value: ['test'],
              props: {
                link: '/',
                options: [
                  { label: 'test', value: 'test' },
                  { label: 'support', value: 'support' },
                ],
              },
            },
            {
              type: 'select',
              name: 'select',
              label: 'Select',
              props: {
                options: [],
              },
            },
          ],
        },
        {
          isLayout: true,
          component: 'FormGroup',
          children: [
            {
              type: 'text',
              name: 'text_2',
              label: 'Text 2',
            },
          ],
        },
      ],
    }
    mountComponent(Form, {
      props,
      attrs: {
        class: 'form',
      },
    })

    checkFormMatchesSnapshot({ wrapperSelector: '.form' })
  })

  it('renders disabled border correctly', () => {
    const props = {
      schema: [
        {
          isLayout: true,
          component: 'FormGroup',
          children: [
            {
              type: 'text',
              required: true,
              name: 'text',
              label: 'Text',
            },
            {
              type: 'tel',
              props: { link: '/' },
              name: 'tel',
              label: 'Tel',
              disabled: true,
            },
            {
              type: 'textarea',
              name: 'textarea',
              label: 'Textarea',
            },
            {
              type: 'date',
              name: 'some_input_2',
              label: 'Date 2',
            },
            {
              type: 'tags',
              name: 'tags',
              label: 'Tags',
              value: ['test'],
              disabled: true,
              props: {
                link: '/',
                options: [
                  { label: 'test', value: 'test' },
                  { label: 'support', value: 'support' },
                ],
              },
            },
            {
              type: 'select',
              name: 'select',
              label: 'Select',
              disabled: true,
              props: {
                options: [],
              },
            },
          ],
        },
      ],
    }
    mountComponent(Form, {
      props,
      attrs: {
        class: 'form',
      },
    })

    checkFormMatchesSnapshot({ wrapperSelector: '.form' })
  })

  it('renders dirty values correctly', () => {
    const props = {
      schema: [
        {
          isLayout: true,
          component: 'FormGroup',
          props: {
            showDirtyMark: true,
          },
          children: [
            {
              type: 'text',
              required: true,
              name: 'text',
              label: 'Text',
            },
            {
              type: 'tel',
              props: { link: '/' },
              name: 'tel',
              label: 'Tel',
            },
            {
              type: 'textarea',
              name: 'textarea',
              label: 'Textarea',
            },
            {
              type: 'date',
              name: 'some_input_2',
              label: 'Date 2',
            },
            {
              type: 'treeselect',
              name: 'treeselect',
              label: 'Treeselect',
              value: ['test'],
              props: {
                link: '/',
                options: [
                  { label: 'test', value: 'test' },
                  { label: 'support', value: 'support' },
                ],
              },
            },
            {
              type: 'select',
              name: 'select',
              label: 'Select',
              props: {
                options: [
                  { label: 'test', value: 'test' },
                  { label: 'support', value: 'support' },
                ],
              },
            },
          ],
        },
        {
          isLayout: true,
          component: 'FormGroup',
          children: [
            {
              type: 'text',
              name: 'text_2',
              label: 'Text 2',
            },
          ],
        },
      ],
    }
    mountComponent(
      {
        components: { Form, DynamicInitializer },
        render() {
          return h('div', [
            h(DynamicInitializer, { name: 'dialog' }),
            h(Form, props),
          ])
        },
      },
      {
        attrs: {
          class: 'form',
        },
      },
    )

    cy.findByLabelText('Text').type('test')
    cy.findByLabelText('Tel').type('+123456789')
    cy.findByLabelText('Textarea').type('test')
    cy.findByLabelText('Date 2').type('2021-01-01')

    cy.findByLabelText('Treeselect')
      .click()
      .then(() => {
        cy.findByRole('option', { name: 'test' }).click()
      })

    cy.findByLabelText('Select')
      .click()
      .then(() => {
        cy.findByRole('option', { name: 'support' }).click()
      })

    cy.findByLabelText('Text 2').type('test')

    checkFormMatchesSnapshot({ wrapperSelector: '.form' })
  })
})
