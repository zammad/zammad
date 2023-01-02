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
        totalCount: 2,
        label: 'Some Label',
      },
      router: true,
      store: true,
    })

    expect(view.container).toHaveTextContent('Some Label')

    const links = view.getAllByRole('link')

    expect(links[0]).toHaveTextContent('Jone Doe')
    expect(links[0], 'has avatar').toHaveTextContent('JD')
    expect(links[1]).toHaveTextContent('Mariland Doe')
    expect(links[1], 'has avatar').toHaveTextContent('MD')
  })

  it('renders show more button', async () => {
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
        totalCount: 5,
        label: 'Some Label',
      },
      router: true,
      store: true,
    })

    expect(view.container).toHaveTextContent('Show 3 more')

    await view.events.click(view.getByRole('button', { name: 'Show 3 more' }))

    expect(view.emitted().showMore).toBeTruthy()
  })

  it('cannot load more, if disabled', async () => {
    const view = renderComponent(CommonUsersList, {
      props: {
        users: [
          {
            id: '123',
            fullname: 'Jone Doe',
            firstname: 'Jone',
            lastname: 'Doe',
          },
        ],
        totalCount: 3,
        disableShowMore: true,
        label: 'Some Label',
      },
      router: true,
      store: true,
    })

    await view.events.click(view.getByRole('button', { name: 'Show 2 more' }))

    expect(view.emitted().showMore).toBeFalsy()
  })
})
