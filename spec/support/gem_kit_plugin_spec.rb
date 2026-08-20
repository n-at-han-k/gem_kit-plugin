# frozen_string_literal: true

# Test support for the plugin spec. Not shipped: the gemspec's file list covers
# lib/ only.

require "tmpdir"
require "fileutils"
require "stringio"

require_relative "../../lib/gem_kit/plugin"

module GemKitPluginSpec
  # A throwaway gem to run the commands against — `gem kit` reads the gemspec
  # in the working directory, even for a command that ignores it.
  def with_gem(version: "1.2.3")
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib/demo"))
      File.write(File.join(dir, "lib/demo/version.rb"), %(module Demo\n  VERSION = "#{version}"\nend\n))
      File.write(File.join(dir, "demo.gemspec"), <<~RUBY)
        require_relative "lib/demo/version"
        Gem::Specification.new do |spec|
          spec.name = "demo"
          spec.version = Demo::VERSION
          spec.authors = ["x"]
          spec.summary = "x"
          spec.files = []
        end
      RUBY

      yield dir
    end
  end

  # Run one `gem kit` invocation with captured streams.
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
end
