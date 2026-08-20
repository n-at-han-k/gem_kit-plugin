# Changelog

All notable changes to gem_kit-plugin are documented in this file. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.1.0] - 2026-08-20

### Added

- `gem kit plugin` — prints a page explaining how a gem adds a command to
  `gem kit`, which this gem did in order to print it. The whole mechanism is a
  `GemKit::Release.plugin` block in `lib/gem_kit/plugin.rb` and a one-line
  `lib/rubygems_plugin.rb` that requires it.
