# frozen_string_literal: true

require_relative "lib/gem_kit/plugin/version"

Gem::Specification.new do |spec|
  spec.name     = "gem_kit-plugin"
  spec.version  = GemKit::Plugin::VERSION
  spec.license  = "MIT"
  spec.summary  = "The smallest possible plugin for `gem kit`"

  spec.description = <<~DESCRIPTION
    gem_kit-release's `gem kit` command takes subcommands from other gems. This
    gem adds one, `gem kit plugin`, which prints a page explaining how it got
    there — and that is all it does. It exists to be read.

    The whole mechanism is a GemKit::Release.plugin block in
    lib/gem_kit/plugin.rb and a one-line lib/rubygems_plugin.rb that requires
    it. RubyGems loads the latter on every `gem` invocation, so installing the
    gem is the whole installation.
  DESCRIPTION

  spec.author   = "Nathan Kidd"
  spec.email    = "nathanblenheimkidd@gmail.com"
  spec.homepage = "https://github.com/n-at-han-k/gem_kit-plugin"

  spec.required_ruby_version = ">= 3.2"

  spec.metadata = {
    "source_code_uri"       => spec.homepage,
    "changelog_uri"         => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri"       => "#{spec.homepage}/issues",
    "rubygems_mfa_required" => "true",
  }

  spec.files = Dir["lib/**/*.rb"] + ["LICENSE", "README.md"]

  spec.require_paths = ["lib"]

  spec.add_dependency "gem_kit", ">= 0.2", "< 1.0"
  spec.add_dependency "gem_kit-release", ">= 0.2.1", "< 1.0"
end
