// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mockGraphQLResult } from '#tests/graphql/builders/mocks.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { mockPublicLinksQuery } from '#shared/entities/public-links/graphql/queries/links.mocks.ts'
import type {
  UserSignupMutation,
  UserSignupResendMutation,
} from '#shared/graphql/types.ts'

import { UserSignupDocument } from '../graphql/mutations/userSignup.api.ts'
import { UserSignupResendDocument } from '../graphql/mutations/userSignupResend.api.ts'

describe('testing additional signup information', () => {
  beforeEach(() => {
    mockApplicationConfig({
      user_create_account: true,
    })
  })

  it('show public links for current screen', async () => {
    const publicLinks = [
      {
        title: 'Imprint',
        link: 'https://example.com/imprint',
        description: null,
      },
      {
        title: 'Privacy policy',
        link: 'https://example.com/privacy',
        description: null,
      },
    ]

    mockPublicLinksQuery({
      publicLinks,
    })

    const view = await visitView('/signup')

    const [imprint, privacy] = publicLinks

    expect(
      await view.findByRole('link', { name: imprint.title }),
    ).toHaveProperty('href', imprint.link)
    expect(
      await view.findByRole('link', { name: privacy.title }),
    ).toHaveProperty('href', privacy.link)
  })

  it('show hint about already existing account', async () => {
    const view = await visitView('/signup')

    expect(
      view.getByText(
        "You're already registered with your email address if you've been in touch with our Support team.",
      ),
    ).toBeInTheDocument()
  })
})

describe('testing additional signup information', () => {
  beforeEach(() => {
    mockApplicationConfig({
      user_create_account: true,
      product_name: 'Zammad Helpdesk',
    })
  })

  it('signup for an new user and resend signup email', async () => {
    const mockerSignup = mockGraphQLResult<UserSignupMutation>(
      UserSignupDocument,
      {
        userSignup: { success: true },
      },
    )

    const mockerVerifyResend = mockGraphQLResult<UserSignupResendMutation>(
      UserSignupResendDocument,
      {
        userSignupResend: { success: true },
      },
    )

    const view = await visitView('/signup')

    expect(await view.findByText('Join Zammad Helpdesk')).toBeInTheDocument()

    const firstname = view.getByLabelText('First name')
    const lastname = view.getByLabelText('Last name')
    const email = view.getByLabelText('Email')
    const password = view.getByLabelText('Password')
    const passwordConfirmation = view.getByLabelText('Confirm password')

    const signupData = {
      firstname: 'John',
      lastname: 'Doe',
      email: 'john.doe@example.com',
      password: 'Example1234',
    }

    await view.events.type(firstname, signupData.firstname)
    await view.events.type(lastname, signupData.lastname)
    await view.events.type(email, signupData.email)
    await view.events.type(password, signupData.password)
    await view.events.type(passwordConfirmation, signupData.password)

    await view.events.click(
      view.getByRole('button', { name: 'Create my account' }),
    )

    const mockSignupCalls = await mockerSignup.waitForCalls()

    expect(mockSignupCalls).toHaveLength(1)
    expect(mockSignupCalls[0].variables).toEqual({
      input: signupData,
    })

    expect(
      await view.findByText(
        `Thanks for joining. Email sent to "${signupData.email}".`,
      ),
    ).toBeInTheDocument()

    expect(
      await view.findByText(
        "Please click on the link in the verification email. If you don't see the email, check other places it might be, like your junk, spam, social, or other folders.",
      ),
    ).toBeInTheDocument()

    expect(
      view.queryByRole('button', { name: 'Create my account' }),
    ).not.toBeInTheDocument()

    expect(
      await view.findByRole('button', { name: 'Resend verification email' }),
    ).toBeInTheDocument()

    // resend the signup email
    await view.events.click(
      view.getByRole('button', { name: 'Resend verification email' }),
    )

    const mockSignupResendCalls = await mockerVerifyResend.waitForCalls()

    expect(mockSignupResendCalls).toHaveLength(1)
    expect(mockSignupResendCalls[0].variables).toEqual({
      email: signupData.email,
    })

    expect(
      await view.findByText(
        `Email sent to "${signupData.email}". Please verify your email account.`,
      ),
    ).toBeInTheDocument()
  })

  it('signup for an new user with not secure password', async () => {
    const mocker = mockGraphQLResult<UserSignupMutation>(UserSignupDocument, {
      userSignup: {
        success: null,
        errors: [
          {
            message:
              'Invalid password, it must contain at least 2 lowercase and 2 uppercase characters!',
            field: 'password',
          },
        ],
      },
    })

    const view = await visitView('/signup')

    const email = view.getByLabelText('Email')
    const password = view.getByLabelText('Password')
    const passwordConfirmation = view.getByLabelText('Confirm password')

    await view.events.type(email, 'john.doe@example.com')
    await view.events.type(password, 'Test1234')
    await view.events.type(passwordConfirmation, 'Test1234')

    await view.events.click(
      view.getByRole('button', { name: 'Create my account' }),
    )

    await mocker.waitForCalls()

    expect(
      await view.findByText(
        'Invalid password, it must contain at least 2 lowercase and 2 uppercase characters!',
      ),
    ).toBeInTheDocument()
  })
})
