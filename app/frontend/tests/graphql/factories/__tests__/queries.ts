// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { UserError, UserInput } from '#shared/graphql/types.ts'
import gql from 'graphql-tag'

export interface TestAvatarQuery {
  accountAvatarActive: {
    id: string
    imageFull: string
    createdAt: string
    updatedAt: string
  }
}

export interface TestUserQuery {
  user: {
    id: string
    fullname: string
  }
}

export interface TestUserAuthorizationsMutation {
  userUpdate: {
    user: {
      id: string
      fullname: string
      authorizations: {
        id: string
        provider: string
      }[]
    }
  }
}

export interface TestUserAuthorizationsVariables {
  userId: string
  input: UserInput
}

export interface TestUserQueryVariables {
  userId: string
}

export const TestAvatarDocument = gql`
  query accountAvatarActive {
    accountAvatarActive {
      id
      imageFull
      createdAt
      updatedAt
    }
  }
`

export const TestUserDocument = gql`
  query user($userId: ID) {
    user(user: { userId: $userId }) {
      id
      fullname
    }
  }
`

export const TestUserAutorizationsDocument = gql`
  mutation userUpdate($userId: ID, $input: UserInput!) {
    userUpdate(id: $userId, input: $input) {
      user {
        id
        fullname
        authorizations {
          id
          provider
        }
      }
    }
  }
`

export interface TestAvatarMutation {
  accountAvatarAdd: {
    avatar: {
      id: string
      imageFull: string
    }
    errors: UserError[]
  }
}

export const TestAvatarActiveMutationDocument = gql`
  mutation accountAvatarAdd($images: AvatarInput!) {
    accountAvatarAdd(images: $images) {
      avatar {
        id
        imageFull
      }
      errors {
        message
        field
      }
    }
  }
`

export interface TestUserUpdatesSubscription {
  userUpdates: {
    user: {
      id: string
      fullname: string
    }
  }
}

export const TestUserUpdatesDocument = gql`
  subscription userUpdates($userId: ID!) {
    userUpdates(userId: $userId) {
      user {
        id
        fullname
      }
    }
  }
`
