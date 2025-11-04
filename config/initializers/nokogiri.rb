# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Nokogori has a default limit of 400 for the maximum tree depth.
# Some emails have a very nested HTML structure that exceeds this limit.
# But emails with much higher nested HTML structure seem to get parsed in no time.
# On top of that, we have a timeout to prevent forever email parsing.
#
# On top of that, Loofah makes impossible to pass the higher limit in conventional ways.
# Thus overriding constant is the only way.
#
# https://github.com/zammad/zammad/issues/5826
Nokogiri::Gumbo.send(:remove_const, :DEFAULT_MAX_TREE_DEPTH)
Nokogiri::Gumbo::DEFAULT_MAX_TREE_DEPTH = 4_000
