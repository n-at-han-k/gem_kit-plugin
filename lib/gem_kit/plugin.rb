# frozen_string_literal: true

require "gem_kit"
require "gem_kit/release/cli"

require_relative "plugin/version"

# The smallest possible plugin for `gem kit`: one command, which prints a page
# telling you how it got there.
#
# Everything below the module is the mechanism, and there is not much of it —
# a GemKit::Release.plugin block, and a lib/rubygems_plugin.rb that requires
# this file. RubyGems loads that on every `gem` invocation, so installing the
# gem is the whole installation.
module GemKit
  module Plugin
    HELP = <<~TXT
      gem kit plugin

      You are looking at a command that came from a different gem.

      `gem kit` is gem_kit-release. This command is gem_kit-plugin, which does
      nothing else — it exists to be read. Two files put it here:

        lib/gem_kit/plugin.rb     the command, in a GemKit::Release.plugin block
        lib/rubygems_plugin.rb    one line: require_relative "gem_kit/plugin"

      RubyGems loads rubygems_plugin.rb from every installed gem, every time you
      run `gem` anything. So there is no wiring: install the gem and the command
      is there, listed by `gem kit`, documented by `gem kit help plugin`, and
      taking --gem like the built-in ones.

      To write your own:

        # lib/gem_kit/your_thing.rb
        require "gem_kit/release/cli"

        GemKit::Release.plugin do
          desc "your-command", "What it does"
          def your_command
            # ...
          end
        end

        # lib/rubygems_plugin.rb
        require_relative "gem_kit/your_thing"

      The block is evaluated on the Thor class, so the whole Thor DSL is in
      scope: desc, long_desc, method_option, map for an alias, and register for
      a Thor::Group generator — which is how `gem kit setup` is built.

      Keep rubygems_plugin.rb to the one require. It runs on every `gem list`
      too, and anything heavy in there is a tax on all of them.
    TXT
  end
end

GemKit::Release.plugin do
  desc "plugin", "Explain how a gem adds a command to `gem kit` (this one did)"
  long_desc GemKit::Plugin::HELP
  def plugin
    $stdout.puts(GemKit::Plugin::HELP)
  end
end
