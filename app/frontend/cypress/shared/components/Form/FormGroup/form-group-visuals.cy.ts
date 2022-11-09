// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

// To update snapshots, run `yarn cypress:snapshots`
// DO NOT update snapshots, when running with --open flag (Cypress GUI)

import { checkFormMatchesSnapshot, mountComponent } from '@cy/utils'
import Form from '@shared/components/Form/Form.vue'

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
})
