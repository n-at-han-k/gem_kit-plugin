# gem_kit-plugin

The smallest possible plugin for [`gem kit`](https://github.com/n-at-han-k/gem_kit).
It adds one command, which prints a page telling you how it got there. That is
all it does — it exists to be read.

```sh
$ gem kit plugin
gem kit plugin

You are looking at a command that came from a different gem.
...
```

## The whole mechanism

Two files.

```ruby
# lib/gem_kit/plugin.rb
require "gem_kit"
require "gem_kit/release/cli"

GemKit::Release.plugin do
  desc "plugin", "Explain how a gem adds a command to `gem kit` (this one did)"
  def plugin
    $stdout.puts(GemKit::Plugin::HELP)
  end
end
```

```ruby
# lib/rubygems_plugin.rb
require_relative "gem_kit/plugin"
```

RubyGems loads `rubygems_plugin.rb` from every installed gem on every `gem`
invocation, so installing the gem is the whole installation. Nothing to wire up.

The command is then not second-class — it is listed by `gem kit`, documented by
`gem kit help plugin`, and takes `--gem` like the built-in ones:

```
$ gem kit
Commands:
  gem kit bump [SEGMENT]          # Move the gem version, refusing to bump on...
  gem kit plugin                  # Explain how a gem adds a command to `gem ...
  gem kit release                 # Gate, build and push this gem
  ...
```

## Writing your own

1. Depend on `gem_kit-release`.
2. Put your commands in a `GemKit::Release.plugin` block.
3. Ship a `lib/rubygems_plugin.rb` that requires the file holding it.

The block is evaluated on the Thor class, so the whole Thor DSL is in scope:
`desc`, `long_desc`, `method_option`, `map` for an alias, and `register` for a
`Thor::Group` generator — which is how `gem kit setup` is built.

Keep `rubygems_plugin.rb` to the one require. It runs on every `gem list` too,
and anything heavy in there is a tax on all of them.

## Install

```ruby
# Gemfile
gem "gem_kit-plugin", group: :development
```

## Development

```sh
direnv allow      # or: nix develop
bin/test
```

## License

MIT
