// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import * as ActionCable from '@rails/actioncable'
import log from '@shared/utils/log'

ActionCable.adapters.logger = log as unknown as Console
ActionCable.logger.enabled = true

export default ActionCable.createConsumer()
