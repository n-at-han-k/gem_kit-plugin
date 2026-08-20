# frozen_string_literal: true

# RubyGems loads this file from every installed gem's lib/ on every `gem`
# invocation. Requiring the plugin here is what puts `gem kit audit` and
# `gem kit skill` on the command line without anyone wiring anything up.
#
# Keep it to the one require: this runs even for `gem list`.

require_relative "gem_kit/plugin"
