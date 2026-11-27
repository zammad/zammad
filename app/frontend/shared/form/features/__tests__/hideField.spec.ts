// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createNode } from '@formkit/core'
import { createLibraryPlugin } from '@formkit/inputs'

import hideField from '../hideField.ts'

const createTextNode = (props: Record<string, unknown>) =>
  createNode({
    plugins: [
      createLibraryPlugin({
        text: {
          type: 'input',
          features: [hideField],
          props: ['label'],
        },
      }),
    ],
    props: {
      type: 'text',
      label: 'example',
      ...props,
    },
  })

describe('hideField', () => {
  it('can hide a field', () => {
    const node = createTextNode({ hidden: true })

    expect(node.props.outerClass).toBe('hidden')

    node.props.hidden = false

    expect(node.props.outerClass).toBe('')
  })

  it('keeps the configured outer classes of a field hidden on creation', () => {
    const node = createTextNode({ hidden: true, outerClass: 'form-group-single-column' })

    expect(node.props.outerClass).toBe('form-group-single-column hidden')

    node.props.hidden = false

    expect(node.props.outerClass).toBe('form-group-single-column')
  })

  it('keeps other outer classes through hide and show round trips', () => {
    const node = createTextNode({ outerClass: 'flex overflow-x-hidden' })

    node.props.hidden = true

    expect(node.props.outerClass).toBe('flex overflow-x-hidden hidden')

    node.props.hidden = false

    expect(node.props.outerClass).toBe('flex overflow-x-hidden')
  })

  it('does not add the hidden class twice', () => {
    const node = createTextNode({ hidden: true, outerClass: 'flex hidden' })

    expect(node.props.outerClass).toBe('flex hidden')
  })

  it('hides a field without configured outer classes', () => {
    const node = createTextNode({})

    node.props.hidden = true

    expect(node.props.outerClass).toBe('hidden')
  })

  it('keeps outer classes given as an object', () => {
    const node = createTextNode({ outerClass: { 'col-span-1': true } })

    node.props.hidden = true

    expect(node.props.outerClass).toEqual({ 'col-span-1': true, hidden: true })

    node.props.hidden = false

    expect(node.props.outerClass).toEqual({ 'col-span-1': true, hidden: false })
  })

  it('shows a field whose object outer classes combine several classes in one key', () => {
    const node = createTextNode({ hidden: true, outerClass: { 'flex hidden': true } })

    node.props.hidden = false

    expect(node.props.outerClass).toEqual({ flex: true, hidden: false })
  })

  it('keeps a class that an object key enables while another key disables it', () => {
    const node = createTextNode({ outerClass: { flex: true, 'flex hidden': false } })

    node.props.hidden = true

    expect(node.props.outerClass).toEqual({ flex: true, hidden: true })

    node.props.hidden = false

    expect(node.props.outerClass).toEqual({ flex: true, hidden: false })
  })

  it('keeps a disabled object class named like an Object method disabled', () => {
    const node = createTextNode({ outerClass: { constructor: false } })

    node.props.hidden = true

    expect(node.props.outerClass).toEqual({ constructor: false, hidden: true })
  })

  it('keeps outer classes given as a function', () => {
    const node = createTextNode({ outerClass: () => 'col-span-1' })

    node.props.hidden = true

    expect(node.props.outerClass(node, 'outer')).toBe('col-span-1 hidden')

    node.props.hidden = false

    expect(node.props.outerClass(node, 'outer')).toBe('col-span-1')
  })
})
