# frozen_string_literal: true

require "gem_kit/release/commands/command"

module GemKit
  module Plugin
    module Commands
      # `gem kit audit` — the ordinary-command shape.
      #
      # It subclasses GemKit::Release::Commands::Command, which is what buys it
      # `project` (the gemspec in the working directory, or the one named by
      # `--gem`), `say`, `refuse` and `fail_with`. A plugin command does not
      # have to: any object the Thor method can call will do. Subclassing just
      # means the `--gem` handling and the failure protocol are already right.
      class Audit < GemKit::Release::Commands::Command
        # Each check is a question about the gemspec and a sentence for when
        # the answer is no. `serious` is what decides the exit status without
        # --strict: a gem with no licence is a problem for its users, a gem
        # with no changelog_uri is a missed link on a web page.
        Check = Struct.new(:label, :serious, :test, keyword_init: true)

        CHECKS = [
          Check.new(label: "no summary", serious: true,
                    test: ->(spec) { spec.summary.to_s.strip.empty? }),
          Check.new(label: "description merely repeats the summary", serious: false,
                    test: ->(spec) { spec.description.to_s.strip == spec.summary.to_s.strip }),
          Check.new(label: "no licence", serious: true,
                    test: ->(spec) { spec.licenses.empty? }),
          Check.new(label: "no homepage", serious: true,
                    test: ->(spec) { spec.homepage.to_s.strip.empty? }),
          Check.new(label: "no author", serious: true,
                    test: ->(spec) { spec.authors.compact.empty? }),
          Check.new(label: "no required_ruby_version", serious: false,
                    test: ->(spec) { spec.required_ruby_version.to_s == ">= 0" }),
          Check.new(label: "no changelog_uri in metadata", serious: false,
                    test: ->(spec) { spec.metadata["changelog_uri"].to_s.empty? }),
          Check.new(label: "no source_code_uri in metadata", serious: false,
                    test: ->(spec) { spec.metadata["source_code_uri"].to_s.empty? }),
          Check.new(label: "ships no files", serious: true,
                    test: ->(spec) { spec.files.empty? }),
        ].freeze

        def call
          findings = CHECKS.select { |check| check.test.call(project.spec) }
          findings += file_findings

          if findings.empty?
            say("#{project.name} #{project.version}: nothing to report.")
            return
          end

          say("#{project.name} #{project.version}: #{findings.size} finding(s)")
          findings.each { |finding| say("  #{finding.serious ? "!" : "-"} #{finding.label}") }

          serious = findings.count(&:serious)
          say
          say("#{serious} serious, #{findings.size - serious} advisory.")

          fail_with("audit failed") if serious.positive? || options[:strict]
        end

        private

          # Two things that are about the repository rather than the gemspec
          # object, and are wrong often enough to be worth naming.
          def file_findings
            findings = []

            unless File.exist?(project.changelog_path)
              findings << Check.new(label: "no #{File.basename(project.changelog_path)}", serious: false)
            end

            unless File.exist?(project.version_file)
              findings << Check.new(label: "no version file at #{relative(project.version_file)}", serious: true)
            end

            findings
          end
      end
    end
  end
end

__END__

describe "gem_kit/plugin/commands/audit" do
  require_relative "../../../../spec/support/gem_kit_plugin_spec"
  extend GemKitPluginSpec

  it "reports nothing for a gemspec that says everything" do
    with_gem(complete: true) do |dir|
      status, out, _err = invoke(["audit"], dir)

      status.should == 0
      out.should.match(/demo 1\.2\.3: nothing to report/)
    end
  end

  it "names what a bare gemspec is missing, and fails on the serious ones" do
    with_gem(complete: false) do |dir|
      status, out, err = invoke(["audit"], dir)

      status.should == 1
      out.should.match(/no licence/)
      out.should.match(/no homepage/)
      out.should.match(/ships no files/)
      out.should.match(/serious/)
      err.should.match(/audit failed/)
    end
  end

  it "marks advisory findings differently from serious ones" do
    with_gem(complete: true) do |dir|
      # Everything serious is in place; only the metadata links are missing.
      File.write(File.join(dir, "demo.gemspec"), File.read(File.join(dir, "demo.gemspec"))
        .sub(/  spec.metadata = .*\n/, ""))

      status, out, _err = invoke(["audit"], dir)

      status.should == 0
      out.should.match(/- no changelog_uri in metadata/)
      out.should.match(/0 serious/)
    end
  end

  it "--strict fails on advisory findings too" do
    with_gem(complete: true) do |dir|
      File.write(File.join(dir, "demo.gemspec"), File.read(File.join(dir, "demo.gemspec"))
        .sub(/  spec.metadata = .*\n/, ""))

      invoke(["audit", "--strict"], dir).first.should == 1
    end
  end

  it "reports a missing changelog and version file" do
    with_gem(complete: true) do |dir|
      File.delete(File.join(dir, "CHANGELOG.md"))

      _status, out, _err = invoke(["audit"], dir)
      out.should.match(/no CHANGELOG\.md/)
    end
  end

  it "takes --gem like a built-in command" do
    with_gem(complete: true, second_gem: true) do |dir|
      invoke(["audit"], dir).first.should == 1          # ambiguous, refuses
      invoke(["audit", "--gem", "demo"], dir).first.should == 0
    end
  end
end
