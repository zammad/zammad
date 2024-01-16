import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './setSystemInformation.api.ts'

export function mockGuidedSetupSetSystemInformationMutation(defaults: Mocks.MockDefaultsValue<Types.GuidedSetupSetSystemInformationMutation, Types.GuidedSetupSetSystemInformationMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.GuidedSetupSetSystemInformationDocument, defaults)
}

export function waitForGuidedSetupSetSystemInformationMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.GuidedSetupSetSystemInformationMutation>(Operations.GuidedSetupSetSystemInformationDocument)
}
