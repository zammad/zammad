// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
import CommonShowMoreButton from '../CommonShowMoreButton.vue'

it('renders show more button', async () => {
  const view = renderComponent(CommonShowMoreButton, {
    props: {
      entities: [
        {
          id: '123',
          fullname: 'Jone Doe',
          firstname: 'Jone',
          lastname: 'Doe',
        },
        {
          id: '321',
          fullname: 'Mariland Doe',
          firstname: 'Mariland',
          lastname: 'Doe',
        },
      ],
      totalCount: 5,
    },
    router: true,
    store: true,
  })

  expect(view.container).toHaveTextContent('Show 3 more')
})

it('cannot load more, if disabled', async () => {
  const view = renderComponent(CommonShowMoreButton, {
    props: {
      entities: [
        {
          id: '123',
          fullname: 'Jone Doe',
          firstname: 'Jone',
          lastname: 'Doe',
        },
      ],
      totalCount: 3,
      disabled: true,
    },
    router: true,
    store: true,
  })

  await view.events.click(view.getByRole('button', { name: 'Show 2 more' }))

  expect(view.getByRole('button')).toBeDisabled()
})
