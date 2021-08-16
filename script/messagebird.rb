# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'messagebird'

client = MessageBird::Client.new('OSR2zUFd14Nd5snb8zmEQYoBx')
client.message_create('Zammad GmbH', '+4917670333748', 'This is a test messageNEW', reference: 'Foobar')
