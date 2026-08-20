# gem_kit-plugin

A worked example of extending [`gem kit`](https://github.com/n-at-han-k/gem_kit)
from another gem. It is meant to be read as much as installed.

## The whole mechanism

Two files. `lib/gem_kit/plugin.rb`:

```ruby
require "gem_kit"
require "gem_kit/release/cli"

GemKit::Release.plugin do
  desc "audit", "Report what this gem is missing before anyone depends on it"
  method_option :strict, type: :boolean, default: false
  def audit
    GemKit::Plugin::Commands::Audit.new(options).call
  end

  register(GemKit::Plugin::Generators::Skill, "skill", "skill NAME",
           "Generate an agent skill directory for this gem")
end
```

and `lib/rubygems_plugin.rb`:

```ruby
require_relative "gem_kit/plugin"
```

RubyGems loads that second file from every installed gem on every `gem`
invocation, so installing this gem is the whole installation. The commands then
sit among the built-in ones:

```sh
$ gem kit
Commands:
  gem kit audit                   # Report what this gem is missing before an...
  gem kit bump [SEGMENT]          # Move the gem version, refusing to bump on...
  gem kit changelog [VERSION]     # Lint CHANGELOG.md, or have an AI CLI writ...
  gem kit deprecations [VERSION]  # List the deprecations this gem has not ye...
  gem kit release                 # Gate, build and push this gem
  gem kit setup                   # Copy DEPRECATIONS.md and RELEASE.md into ...
  gem kit skill NAME              # Generate an agent skill directory for this gem
  gem kit tag                     # Tag the current version in git
```

They are not second-class: they appear in the listing, take `--gem`, and get a
help page from `gem kit help audit`.

The block is evaluated on the Thor class, so the whole Thor DSL is in scope —
`desc`, `long_desc`, `method_option`, `map` for an alias, and `register` for a
`Thor::Group` generator.

## The two shapes an extension can take

This gem adds one of each, which is the reason it adds two.

### An ordinary command — `gem kit audit`

```sh
$ gem kit audit
demo 1.2.3: 3 finding(s)
  ! no licence
  ! no homepage
  - no changelog_uri in metadata

1 serious, 2 advisory.
```

It reports what a gem is judged on and rarely told about: a description that
merely repeats the summary, a missing licence or homepage, absent metadata
links, a version file the gemspec reads but that is not there.

Findings are advice, not gates — it exits non-zero on the serious ones so CI
can choose to care, and `--strict` makes any finding count.

The class behind it subclasses `GemKit::Release::Commands::Command`, which is
what gives it `project` (the gemspec in the working directory, or the one named
by `--gem`), `say`, `refuse` and `fail_with`. **A plugin command does not have
to** — any object your Thor method can call will do. Subclassing just means the
`--gem` handling and the failure protocol are already right.

### A generator — `gem kit skill NAME`

```sh
$ gem kit skill using-demo
      create  .agents/skills/using-demo/SKILL.md
```

A `Thor::Group` with `Thor::Actions`, exactly as `gem kit setup` is — so it
gets the same machinery Rails generators have: `create` / `identical` /
`conflict` reporting, a prompt before overwriting something that differs, and
`--force`, `--skip`, `--pretend` and `--quiet` from one call to
`add_runtime_options!`.

What it writes is an agent skill whose frontmatter is filled in from your
gemspec, so an agent working in a project that depends on your gem is told how
to use it. The body is left as `TODO:` prompts, because a generated skill that
pretends to know your library is worse than an honest blank.

## Install

```ruby
# Gemfile
gem "gem_kit-plugin", group: :development
```

Or `gem install gem_kit-plugin`. It depends on `gem_kit` and
`gem_kit-release`, so installing it brings `gem kit` with it.

## Writing your own

1. Depend on `gem_kit-release`.
2. Put your commands in a `GemKit::Release.plugin` block.
3. Ship a `lib/rubygems_plugin.rb` that requires the file holding it.

Keep `rubygems_plugin.rb` to the one require: it runs on every `gem`
invocation, including `gem list`, and anything heavy there is a tax on all of
them.

## Development

```sh
direnv allow      # or: nix develop
bin/test
```

## License

MIT
