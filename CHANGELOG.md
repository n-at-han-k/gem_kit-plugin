# Changelog

All notable changes to gem_kit-plugin are documented in this file. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.1.0] - 2026-08-20

### Added

- `gem kit audit` — reports what a gem is missing before anyone depends on it:
  a description that merely repeats the summary, a missing licence, homepage or
  author, absent metadata links, a version file the gemspec reads but that is
  not there. Serious findings fail; `--strict` makes every finding fail.
- `gem kit skill NAME` — generates an agent skill directory for the gem, with
  frontmatter filled in from the gemspec. A `Thor::Group` generator, so it
  reports `create` / `identical` / `conflict` and takes `--force`, `--skip` and
  `--pretend`.
- Both are registered through one `GemKit::Release.plugin` block in
  `lib/gem_kit/plugin.rb`, loaded by a one-line `lib/rubygems_plugin.rb`. That
  is the whole extension mechanism, and the reason this gem exists: it is an
  example to read.
