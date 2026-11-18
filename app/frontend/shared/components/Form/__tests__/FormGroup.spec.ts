// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { waitFor } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitUntil } from '#tests/support/utils.ts'

import Form from '#shared/components/Form/Form.vue'
import FormGroup from '#shared/components/Form/FormGroup.vue'

const half = (name: string, extraClass = '') =>
  `<div data-name="${name}" class="form-group-single-column ${extraClass}"></div>`

const full = (name: string) => `<div data-name="${name}"></div>`

const renderFormGroup = (fields: string[], props: Record<string, unknown> = {}) =>
  renderComponent(FormGroup, {
    props,
    slots: { default: fields.join('') },
  })

const unpairedFields = (container: Element) =>
  Array.from(container.querySelectorAll('[data-form-group-unpaired]')).map((element) =>
    element.getAttribute('data-name'),
  )

describe('FormGroup.vue', () => {
  it.each([
    ['a single half-size field', [half('a')], ['a']],
    ['a pair of half-size fields', [half('a'), half('b')], []],
    ['an odd run of half-size fields', [half('a'), half('b'), half('c')], ['c']],
    ['half-size fields split by a full-width one', [half('a'), full('b'), half('c')], ['a', 'c']],
    [
      'runs restarting after a full-width field',
      [half('a'), half('b'), half('c'), full('d'), half('e'), half('f'), half('g')],
      ['c', 'g'],
    ],
    ['a hidden partner', [half('a'), half('b', 'hidden')], ['a']],
    ['a pair around a hidden field', [half('a'), half('b', 'hidden'), half('c')], []],
    ['a pair around a hidden input', [half('a'), '<input type="hidden" />', half('b')], []],
    ['full-width fields only', [full('a'), full('b')], []],
    ['a group of half-size fields', [full('a'), full('b'), full('c')], ['c'], true],
    [
      'a group of half-size fields with a hidden input',
      ['<input type="hidden" />', full('a'), full('b')],
      [],
      true,
    ],
  ])('marks the unpaired fields for %s', async (_, fields, expected, halfSizeFields = false) => {
    const view = renderFormGroup(fields, { halfSizeFields })

    await waitFor(() => expect(unpairedFields(view.container)).toEqual(expected))
  })

  it('updates the marks when halfSizeFields changes', async () => {
    const view = renderFormGroup([full('a'), full('b'), full('c')], { halfSizeFields: true })

    expect(view.container.querySelector('.form-group')).toHaveClass('form-group-half-size-fields')

    await waitFor(() => expect(unpairedFields(view.container)).toEqual(['c']))

    await view.rerender({ halfSizeFields: false })

    await waitFor(() => expect(unpairedFields(view.container)).toEqual([]))
  })

  it('updates the marks when fields are added or change their size', async () => {
    const view = renderFormGroup([half('a'), half('b')])
    const group = view.container.querySelector('.form-group')!

    await waitFor(() => expect(unpairedFields(view.container)).toEqual([]))

    group.insertAdjacentHTML('beforeend', half('c'))

    await waitFor(() => expect(unpairedFields(view.container)).toEqual(['c']))

    group.querySelector('[data-name="b"]')!.classList.remove('form-group-single-column')

    await waitFor(() => expect(unpairedFields(view.container)).toEqual(['a', 'c']))

    group.querySelector('[data-name="c"]')!.classList.remove('form-group-single-column')

    await waitFor(() => expect(unpairedFields(view.container)).toEqual(['a']))
  })

  it('follows fields hidden and shown again in a form', async () => {
    const view = renderComponent(Form, {
      form: true,
      props: {
        id: 'pairing-form',
        schema: [
          {
            isLayout: true,
            component: 'FormGroup',
            children: ['first', 'second', 'third'].map((name) => ({
              type: 'text',
              name,
              label: name,
              outerClass: 'form-group-single-column',
            })),
          },
        ],
      },
    })

    await waitUntil(() => view.emitted().settled)

    const field = (name: string) => getNode('pairing-form')!.at(name)!

    const unpairedLabels = () =>
      Array.from(view.container.querySelectorAll('[data-form-group-unpaired] label')).map(
        (label) => label.textContent,
      )

    await waitFor(() => expect(unpairedLabels()).toEqual(['third']))

    field('second').props.hidden = true

    await waitFor(() => expect(unpairedLabels()).toEqual([]))

    field('third').props.hidden = true

    await waitFor(() => expect(unpairedLabels()).toEqual(['first']))

    field('second').props.hidden = false

    await waitFor(() => expect(unpairedLabels()).toEqual([]))
  })
})
