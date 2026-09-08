// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { existsSync } from 'node:fs'
import { join } from 'node:path'

import { renderComponent, type ExtendedRenderResult } from '#tests/support/components/index.ts'

import type { KnowledgeBaseIconSet } from '#desktop/entities/knowledge-base/types.ts'

import KnowledgeBaseCategoryIcon from '../KnowledgeBaseCategoryIcon.vue'

const iconSets: KnowledgeBaseIconSet[] = [
  'anticon',
  'FontAwesome',
  'material',
  'ionicons',
  'Simple-Line-Icons',
]

const renderIcon = (props: Record<string, unknown> = {}) =>
  renderComponent(KnowledgeBaseCategoryIcon, {
    props: {
      name: 'folder',
      set: 'material',
      ...props,
    },
  })

// The shared icon queries only match the app-internal `#icon-…` sprite, while
//   this component references an external icon font file.
const getIcon = (wrapper: ExtendedRenderResult) =>
  wrapper.container.querySelector('svg') as SVGElement

const getSpriteHref = (wrapper: ExtendedRenderResult) =>
  wrapper.container.querySelector('use')?.getAttribute('href')

describe('KnowledgeBaseCategoryIcon', () => {
  it('renders the icon as a sprite reference', () => {
    const wrapper = renderIcon({ name: 'folder' })

    expect(getIcon(wrapper)).toHaveClass('icon', 'icon-folder')
    expect(getSpriteHref(wrapper)).toBe('/assets/icon-fonts/material.svg#icon-folder')
  })

  it.each(iconSets)('resolves the icon of the "%s" icon set', (set) => {
    const wrapper = renderIcon({ name: 'book', set })

    expect(getSpriteHref(wrapper)).toBe(`/assets/icon-fonts/${set}.svg#icon-book`)
  })

  it.each(iconSets)('references an existing sprite file for the "%s" icon set', (set) => {
    // The sprite is served from the public folder, so a renamed or missing icon
    //   font would silently break the reference above.
    expect(existsSync(join(process.cwd(), 'public/assets/icon-fonts', `${set}.svg`))).toBe(true)
  })

  it('renders in medium size by default', () => {
    const wrapper = renderIcon()

    expect(getIcon(wrapper)).toHaveAttribute('width', '32')
    expect(getIcon(wrapper)).toHaveAttribute('height', '32')
  })

  it.each([
    { size: 'tiny', pixels: '16' },
    { size: 'small', pixels: '20' },
    { size: 'large', pixels: '48' },
  ] as const)('renders in $size size', ({ size, pixels }) => {
    const wrapper = renderIcon({ size })

    expect(getIcon(wrapper)).toHaveAttribute('width', pixels)
    expect(getIcon(wrapper)).toHaveAttribute('height', pixels)
  })

  it('prefers a fixed size over the size preset', () => {
    const wrapper = renderIcon({ size: 'small', fixedSize: { width: 120, height: 60 } })

    expect(getIcon(wrapper)).toHaveAttribute('width', '120')
    expect(getIcon(wrapper)).toHaveAttribute('height', '60')
  })

  it('renders decoratively, because the category title provides the name', () => {
    const wrapper = renderIcon()

    expect(getIcon(wrapper)).toHaveAttribute('aria-hidden', 'true')
    expect(getIcon(wrapper)).not.toHaveAccessibleName()
  })

  it('carries an accessible name when it stands in for a label', () => {
    const wrapper = renderIcon({ label: 'Folder Open' })

    expect(getIcon(wrapper)).not.toHaveAttribute('aria-hidden')
    expect(getIcon(wrapper)).toHaveAccessibleName('Folder Open')
  })
})
