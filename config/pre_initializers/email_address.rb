# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# EmailAddress gem clashes with EmailAddress model.
# https://github.com/afair/email_address#namespace-conflict-resolution
EmailAddressValidator = EmailAddress
Object.send(:remove_const, :EmailAddress)
