# :stopdoc:
#
# A diagnostic context allows us to attach state information to every log
# message. This is useful for applications that serve client requests -
# information about the client can be included in the log messages for the
# duration of the request processing. This allows you to identify related log
# messages in concurrent system.
#
# The Mapped Diagnostic Context tracks state information in a collection of
# key/value pairs. In this example we are creating a few threads that will log
# quotes from famous people. Each thread has its own diagnostic context
# containing the name of the famous person.
#
# Our PatternLayout is configured to attach the "first" and the "last" name of
# our famous person to each log message.
#

  require 'logging'

  # log the first and last names of the celebrity with each quote
  Logging.appenders.stdout(
    :layout => Logging.layouts.pattern(:pattern => '%X{first} %X{last}: %m\n')
  )

  log = Logging.logger['User']
  log.add_appenders 'stdout'
  log.level = :debug

  Logging.mdc['first'] = 'John'
  Logging.mdc['last']  = 'Doe'

  # in this first thread we will log some quotes by Allan Rickman
  t1 = Thread.new {
    Logging.mdc['first'] = 'Allan'
    Logging.mdc['last']  = 'Rickman'

    [ %q{I've never been able to plan my life. I just lurch from indecision to indecision.},
      %q{If only life could be a little more tender and art a little more robust.},
      %q{I do take my work seriously and the way to do that is not to take yourself too seriously.},
      %q{I'm a quite serious actor who doesn't mind being ridiculously comic.}
    ].each { |quote|
      sleep rand
      log.info quote
    }
  }

  # in this second thread we will log some quotes by William Butler Yeats
  t2 = Thread.new {
    Logging.mdc['first']  = 'William'
    Logging.mdc['middle'] = 'Butler'
    Logging.mdc['last']   = 'Yeats'

    [ %q{Tread softly because you tread on my dreams.},
      %q{The best lack all conviction, while the worst are full of passionate intensity.},
      %q{Education is not the filling of a pail, but the lighting of a fire.},
      %q{Do not wait to strike till the iron is hot; but make it hot by striking.},
      %q{People who lean on logic and philosophy and rational exposition end by starving the best part of the mind.}
    ].each { |quote|
      sleep rand
      log.info quote
    }
  }

  # and in this third thread we will log some quotes by Bono
  t3 = Thread.new {
    Logging.mdc.clear  # otherwise we inherit the last name "Doe"
    Logging.mdc['first'] = 'Bono'

    [ %q{Music can change the world because it can change people.},
      %q{The less you know, the more you believe.}
    ].each { |quote|
      sleep rand
      log.info quote
    }
  }

  t1.join
  t2.join
  t3.join

  log.info %q{and now we are done}

# :startdoc:
