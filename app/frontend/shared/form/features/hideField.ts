// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'

type ClassFunction = (...args: unknown[]) => unknown

// Points each wrapper at the configured function, so a toggle never wraps a previous wrapper.
const configuredClassFunctions = new WeakMap<ClassFunction, ClassFunction>()

const toggleHiddenClass = (outerClass: unknown, hidden: boolean): unknown => {
  if (typeof outerClass === 'function') {
    const configured =
      configuredClassFunctions.get(outerClass as ClassFunction) ?? (outerClass as ClassFunction)
    const wrapper: ClassFunction = (...args) => toggleHiddenClass(configured(...args), hidden)

    configuredClassFunctions.set(wrapper, configured)

    return wrapper
  }

  // FormKit adds an object key as a whole, so a key like 'flex hidden' has to be split up.
  //   A class enabled by any key stays enabled, as it was before the split.
  if (outerClass && typeof outerClass === 'object') {
    // Without a prototype, a class named like an Object method (e.g. 'constructor') reads as unset.
    const classes: Record<string, unknown> = Object.create(null)

    Object.entries(outerClass).forEach(([key, enabled]) => {
      key
        .split(/\s+/)
        .filter(Boolean)
        .forEach((className) => {
          classes[className] = classes[className] || enabled
        })
    })

    return { ...classes, hidden }
  }

  const classNames =
    typeof outerClass === 'string'
      ? outerClass.split(/\s+/).filter((className) => className && className !== 'hidden')
      : []

  if (hidden) classNames.push('hidden')

  return classNames.join(' ')
}

const hideField = (node: FormKitNode) => {
  node.addProps(['hidden'])

  node.on('created', () => {
    const { props } = node

    if (props.hidden) {
      props.outerClass = toggleHiddenClass(props.outerClass, true)
    }

    node.on('prop:hidden', ({ payload }) => {
      props.outerClass = toggleHiddenClass(props.outerClass, Boolean(payload))
    })
  })
}

export default hideField
