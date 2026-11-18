// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page } from 'vitest/browser'

import { mountComponent } from '#tests/browser/utils.ts'

import Form from '#shared/components/Form/Form.vue'

const mountFormGroup = async (
  fields: { name: string; halfSize?: boolean; outerClass?: string }[],
  { width = '600px', halfSizeFields = false } = {},
) => {
  await mountComponent(Form, {
    style: { width },
    schema: [
      {
        isLayout: true,
        component: 'FormGroup',
        props: { halfSizeFields },
        children: fields.map(({ name, halfSize, outerClass }) => ({
          type: 'text',
          name,
          label: name,
          outerClass: halfSize ? 'form-group-single-column' : outerClass,
        })),
      },
    ],
  })

  await expect.element(page.getByLabelText(fields[0].name)).toBeVisible()
}

const formGroup = () => document.querySelector<HTMLElement>('.form-group')!

const fieldRect = (name: string) =>
  page.getByLabelText(name).element().closest('.formkit-outer')!.getBoundingClientRect()

// Compares each field with the resolved grid tracks, so that a field of any other width is reported with its width.
const fieldWidths = (...names: string[]) => {
  const { gridTemplateColumns, columnGap } = getComputedStyle(formGroup())
  const [firstTrack, secondTrack] = gridTemplateColumns.split(' ').map(Number.parseFloat)
  const fullWidth = firstTrack + Number.parseFloat(columnGap) + secondTrack

  const matches = (width: number, expected: number) => Math.abs(width - expected) < 1

  return names.map((name) => {
    const { width } = fieldRect(name)

    if (matches(width, fullWidth)) return 'full'
    if (matches(width, firstTrack)) return 'half'

    return width
  })
}

const isSameRow = (...names: string[]) =>
  new Set(names.map((name) => fieldRect(name).top)).size === 1

describe('form group columns', () => {
  it('shows a single half-size field at full width', async () => {
    await mountFormGroup([{ name: 'State', halfSize: true }])

    expect(fieldWidths('State')).toEqual(['full'])
  })

  it('widens the last field of an odd run of half-size fields', async () => {
    await mountFormGroup([
      { name: 'First', halfSize: true },
      { name: 'Second', halfSize: true },
      { name: 'Third', halfSize: true },
      { name: 'Street' },
      { name: 'Zip', halfSize: true },
      { name: 'City', halfSize: true },
    ])

    expect(fieldWidths('First', 'Second', 'Third', 'Street', 'Zip', 'City')).toEqual([
      'half',
      'half',
      'full',
      'full',
      'half',
      'half',
    ])
    expect(isSameRow('First', 'Second')).toBe(true)
    expect(isSameRow('Zip', 'City')).toBe(true)
  })

  it('pairs a half-size field with a manually sized one', async () => {
    await mountFormGroup([
      { name: 'State', halfSize: true },
      { name: 'Priority', outerClass: 'col-span-1' },
    ])

    await expect.poll(() => fieldWidths('State', 'Priority')).toEqual(['half', 'half'])
    expect(isSameRow('State', 'Priority')).toBe(true)
  })

  it('pairs a half-size field with one sized manually from the same breakpoint on', async () => {
    await mountFormGroup([
      { name: 'Password', outerClass: 'col-span-full @md:col-span-1' },
      { name: 'Confirm', halfSize: true },
    ])

    await expect.poll(() => fieldWidths('Password', 'Confirm')).toEqual(['half', 'half'])
    expect(isSameRow('Password', 'Confirm')).toBe(true)
  })

  it('pairs a half-size field with a manually sized one only while that spans one column', async () => {
    await mountFormGroup(
      [
        { name: 'State', halfSize: true },
        { name: 'Priority', outerClass: 'col-span-full @lg:col-span-1' },
      ],
      { width: '480px' },
    )

    expect(fieldWidths('State', 'Priority')).toEqual(['full', 'full'])

    formGroup().style.width = '600px'

    await expect.poll(() => fieldWidths('State', 'Priority')).toEqual(['half', 'half'])
    expect(isSameRow('State', 'Priority')).toBe(true)
  })

  it('shows a half-size field next to a manually sized full-width one at full width', async () => {
    await mountFormGroup([
      { name: 'State', halfSize: true },
      { name: 'Priority', outerClass: 'col-span-2' },
    ])

    expect(fieldWidths('State', 'Priority')).toEqual(['full', 'full'])
  })

  it('pairs a half-size field with one spanning one column from its end line', async () => {
    await mountFormGroup([
      { name: 'State', halfSize: true },
      { name: 'Priority', outerClass: '[grid-column:auto/span_1]' },
    ])

    await expect.poll(() => fieldWidths('State', 'Priority')).toEqual(['half', 'half'])
    expect(isSameRow('State', 'Priority')).toBe(true)
  })

  it('shows a single field at full width in a group of half-size fields', async () => {
    await mountFormGroup([{ name: 'State' }], { width: '400px', halfSizeFields: true })

    expect(fieldWidths('State')).toEqual(['full'])
  })

  it('pairs the fields of a group of half-size fields', async () => {
    await mountFormGroup([{ name: 'State' }, { name: 'Priority' }, { name: 'Owner' }], {
      width: '400px',
      halfSizeFields: true,
    })

    expect(fieldWidths('State', 'Priority', 'Owner')).toEqual(['half', 'half', 'full'])
    expect(isSameRow('State', 'Priority')).toBe(true)
  })
})
