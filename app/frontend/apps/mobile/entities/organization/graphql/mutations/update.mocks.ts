import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './update.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockOrganizationUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.OrganizationUpdateMutation, Types.OrganizationUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.OrganizationUpdateDocument, defaults)
}

export function waitForOrganizationUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.OrganizationUpdateMutation>(Operations.OrganizationUpdateDocument)
}

export function mockOrganizationUpdateMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.OrganizationUpdateDocument, message, extensions);
}
