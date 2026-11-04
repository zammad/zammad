// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page, userEvent } from 'vitest/browser'
import { h } from 'vue'

import { mountComponent } from '#tests/browser/utils.ts'

import DynamicInitializer from '#shared/components/DynamicInitializer/DynamicInitializer.vue'
import Form from '#shared/components/Form/Form.vue'

import type { Component } from 'vue'

const mountForm = async (component: Component, props: Record<string, unknown> = {}) => {
  const view = await mountComponent(component, props)

  return page.elementLocator(view.container.querySelector('.form')!)
}

describe('grouping form fields', () => {
  it('renders basic group', async () => {
    const schema = [
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
    ]

    const form = await mountForm(Form, { schema, class: 'form' })

    await expect.element(form).toMatchScreenshot('basic')
  })

  it('renders disabled border correctly', async () => {
    const schema = [
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
    ]

    const form = await mountForm(Form, { schema, class: 'form' })

    await expect.element(form).toMatchScreenshot('disabled')
  })

  it('renders dirty values correctly', async () => {
    const schema = [
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
    ]

    // The select fields open their options in a dialog.
    const form = await mountForm({
      render: () =>
        h('div', { class: 'form' }, [
          h(DynamicInitializer, { name: 'dialog' }),
          h(Form, { schema }),
        ]),
    })

    const button = (name: string) => page.getByRole('button', { name, exact: true })

    await userEvent.fill(page.getByLabelText('Text', { exact: true }), 'test')
    await userEvent.fill(page.getByLabelText('Tel', { exact: true }), '+123456789')
    await userEvent.fill(page.getByLabelText('Textarea', { exact: true }), 'test')

    // The mobile date field is picker-only, so the date is picked from the decade view down.
    await page.getByLabelText('Date 2', { exact: true }).click()
    await button('Open the months overlay').click()
    await button('Open the years overlay').click()
    for (let decade = Math.floor(new Date().getFullYear() / 10); decade > 202; decade -= 1) {
      // oxlint-disable-next-line no-await-in-loop
      await button('Previous decade').click()
    }
    await button('2021').click()
    await button('January 2021').click()
    await button('Friday, January 1st, 2021').click()

    await page.getByLabelText('Treeselect', { exact: true }).click()
    await page.getByRole('option', { name: 'test', exact: true }).click()

    await page.getByLabelText('Select', { exact: true }).click()
    await page.getByRole('option', { name: 'support', exact: true }).click()

    await userEvent.fill(page.getByLabelText('Text 2', { exact: true }), 'test')

    await expect.element(form).toMatchScreenshot('dirty')
  })
})
