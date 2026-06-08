import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './noteUpdate.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockOrganizationNoteUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.OrganizationNoteUpdateMutation, Types.OrganizationNoteUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.OrganizationNoteUpdateDocument, defaults)
}

export function waitForOrganizationNoteUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.OrganizationNoteUpdateMutation>(Operations.OrganizationNoteUpdateDocument)
}

export function mockOrganizationNoteUpdateMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.OrganizationNoteUpdateDocument, message, extensions);
}
