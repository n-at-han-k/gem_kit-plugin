# frozen_string_literal: true

# Test support shared by the command and generator specs. Not shipped: the
# gemspec's file list covers lib/ only.

require "tmpdir"
require "fileutils"
require "stringio"

require_relative "../../lib/gem_kit/plugin"

module GemKitPluginSpec
  # A throwaway gem. `complete: true` gives it everything the audit asks for,
  # so a spec can subtract exactly the one thing it is about.
  def with_gem(complete: true, second_gem: false, version: "1.2.3")
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib/demo"))
      File.write(File.join(dir, "lib/demo/version.rb"), %(module Demo\n  VERSION = "#{version}"\nend\n))
      File.write(File.join(dir, "lib/demo.rb"), "require_relative 'demo/version'\n")
      File.write(File.join(dir, "demo.gemspec"), gemspec(complete, version))
      File.write(File.join(dir, "CHANGELOG.md"), "# Changelog\n\n## [Unreleased]\n")

      if second_gem
        File.write(File.join(dir, "other.gemspec"), <<~RUBY)
          Gem::Specification.new do |spec|
            spec.name = "other"
            spec.version = "9.9.9"
            spec.authors = ["x"]
            spec.summary = "x"
            spec.files = []
          end
        RUBY
      end

      yield dir
    end
  end

  # Run one `gem kit` invocation with captured streams, returning
  # [status, stdout, stderr].
  def invoke(arguments, dir)
    out, err = StringIO.new, StringIO.new
    saved_out, saved_err = $stdout, $stderr
    $stdout, $stderr = out, err

    begin
      status = Dir.chdir(dir) { GemKit::Release.run(arguments, out: out, err: err) }
    ensure
      $stdout, $stderr = saved_out, saved_err
    end

    [status, out.string, err.string]
  end

  private

    def gemspec(complete, version)
      return <<~RUBY unless complete
        require_relative "lib/demo/version"
        Gem::Specification.new do |spec|
          spec.name = "demo"
          spec.version = Demo::VERSION
          spec.summary = "x"
          spec.files = []
        end
      RUBY

      <<~RUBY
        require_relative "lib/demo/version"
        Gem::Specification.new do |spec|
          spec.name = "demo"
          spec.version = Demo::VERSION
          spec.summary = "A demonstration gem"
          spec.description = "A gem that exists so a spec has something to look at."
          spec.license = "MIT"
          spec.homepage = "https://example.com/demo"
          spec.author = "Someone"
          spec.required_ruby_version = ">= 3.2"
          spec.metadata = { "changelog_uri" => "https://example.com/demo/CHANGELOG.md", "source_code_uri" => "https://example.com/demo" }
          spec.files = ["lib/demo.rb"]
          spec.require_paths = ["lib"]
        end
      RUBY
    end
end
