// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import gql from 'graphql-tag'
import type { TypedDocumentNode } from '@apollo/client/core'

export type ID = number

export type Sample = {
  id: ID
  title?: string
  text?: string
}

export const SampleDocument = gql`
  query getSample($id: ID!) {
    Sample(id: $id) {
      id
      title
      text
    }
  }
`

export const SampleMutationDocument = gql`
  query getSample($id: ID!) {
    Sample(id: $id) {
      id
      title
      text
      errors {
        message
        field
      }
    }
  }
`

export const SampleSubscriptionDocument = gql`
  subscription subscribeSample($id: ID!) {
    sampleUpdated(id: $id) {
      id
      title
      text
    }
  }
`

export type SampleQuery = {
  Sample?: {
    __typename?: 'Sample'
    id?: string
    title?: string
    text?: string
  }
}

export type SampleQueryVariables = {
  id: ID
}

export type SampleUpdatePayload = {
  errors?: string[]
  Sample?: Sample
}

export type SampleUpdateMutation = {
  SampleUpdate?: SampleUpdatePayload
}

export type SampleInput = {
  title?: string
  text?: string[]
}

export type SampleUpdateMutationVariables = {
  id: ID
  Sample: SampleInput
}

export interface SampleUpdatedSubscription {
  SampleUpdated: {
    title?: string
    text?: string
  }
}
export interface SampleUpdatedSubscriptionVariables {
  id: ID
}

export const SampleTypedQueryDocument: TypedDocumentNode<
  SampleQuery,
  SampleQueryVariables
> = SampleDocument

export const SampleTypedMutationDocument: TypedDocumentNode<
  SampleUpdateMutation,
  SampleUpdateMutationVariables
> = SampleMutationDocument

export const SampleTypedSubscriptionDocument: TypedDocumentNode<
  SampleUpdatedSubscription,
  SampleUpdatedSubscriptionVariables
> = SampleSubscriptionDocument
