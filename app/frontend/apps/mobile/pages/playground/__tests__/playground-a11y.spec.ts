// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { configureAxe } from 'vitest-axe'
import { visitView } from '@tests/support/components/visitView'

describe('testing playground a11y', () => {
  it('has no accessibility violations', async () => {
    await visitView('/playground')

    const configuredAxe = configureAxe({
      // NB: Although "Playground" is not covered by any other tests, it is prudent to run at least a violation check.
      //   Considering this screen is used for hoisting experimental components, it might uncover accessibility issues
      //   early in the development process. However, if you need to ignore certain rule during checks of this page,
      //   uncomment and adjust the block below.
      // https://github.com/dequelabs/axe-core/blob/develop/doc/API.md#api-name-axeconfigure
      // https://dequeuniversity.com/rules/axe/4.4
      /*
      rules: {
        label: {
          enabled: false,
        },
      },
      */
    })

    const results = await configuredAxe(document.body)
    expect(results).toHaveNoViolations()
  })
})
