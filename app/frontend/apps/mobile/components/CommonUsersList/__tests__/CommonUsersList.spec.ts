// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
import CommonUsersList from '../CommonUsersList.vue'

describe('list of users with avatars', () => {
  it('renders users', () => {
    const view = renderComponent(CommonUsersList, {
      props: {
        users: [
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
      },
      router: true,
      store: true,
    })

    const links = view.getAllByRole('link')

    expect(links[0]).toHaveTextContent('Jone Doe')
    expect(links[0], 'has avatar').toHaveTextContent('JD')
    expect(links[1]).toHaveTextContent('Mariland Doe')
    expect(links[1], 'has avatar').toHaveTextContent('MD')
  })
})
