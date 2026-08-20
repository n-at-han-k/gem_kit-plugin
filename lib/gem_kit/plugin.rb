# frozen_string_literal: true

require "gem_kit"
require "gem_kit/release/cli"

require_relative "plugin/version"
require_relative "plugin/commands/audit"
require_relative "plugin/generators/skill"

# A worked example of extending `gem kit` from another gem.
#
# Two commands, chosen to show both shapes an extension can take:
#
#   gem kit audit      an ordinary command, backed by a plain object
#   gem kit skill      a Thor::Group generator, with create/identical/conflict
#
# Installing this gem is all it takes. lib/rubygems_plugin.rb requires this
# file, RubyGems loads that on every `gem` invocation, and the commands are
# there — listed by `gem kit`, documented by `gem kit help audit`, and taking
# `--gem` like everything else.
#
# If you are reading this to write your own: the whole mechanism is the
# GemKit::Release.plugin block below. Everything else here is the two commands
# it registers.
module GemKit
  module Plugin
  end
end

GemKit::Release.plugin do
  desc "audit", "Report what this gem is missing before anyone depends on it"
  long_desc <<~TXT
    Checks the things a gem is judged on and rarely told about: a summary and
    description that say different things, a homepage, a licence, a changelog,
    the metadata links RubyGems shows on the gem page, and whether the version
    file the gemspec reads actually exists.

    Findings are advice, not gates. It exits non-zero only so CI can choose to
    care; --strict makes it exit non-zero on any finding at all.
  TXT
  method_option :strict, type: :boolean, default: false,
                         desc: "Exit non-zero on any finding, not just the serious ones"
  def audit
    GemKit::Plugin::Commands::Audit.new(options).call
  end

  register(GemKit::Plugin::Generators::Skill, "skill", "skill NAME",
           "Generate an agent skill directory for this gem")
end
