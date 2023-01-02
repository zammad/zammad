// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

const NodeTypes = {
  ELEMENT: 1,
  ATTRIBUTE: 6,
}

const dataAttributes = new Set(['data-testid', 'data-test-id', 'data-testId'])

const TransformTestId = (node) => {
  if (node.type !== NodeTypes.ELEMENT || !('props' in node)) {
    return
  }

  for (let i = 0; i < node.props.length; i += 1) {
    const p = node.props[i]

    if (p && p.type === NodeTypes.ATTRIBUTE && dataAttributes.has(p.name)) {
      node.props.splice(i, 1)
      i -= 1
    }
  }
}

module.exports = TransformTestId
