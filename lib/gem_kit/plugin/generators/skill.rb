# frozen_string_literal: true

require "thor"
require "thor/group"

require "gem_kit/release/project"

module GemKit
  module Plugin
    module Generators
      # `gem kit skill NAME` — the generator shape.
      #
      # A Thor::Group with Thor::Actions, exactly as `gem kit setup` is, which
      # is the point of the example: a plugin gets the same generator
      # machinery Rails uses — create/identical/conflict reporting, the
      # overwrite prompt, --force, --skip, --pretend — by including it.
      #
      # What it writes is an agent skill: a directory with a SKILL.md whose
      # frontmatter is filled in from the gemspec, so an agent working in a
      # project that depends on your gem is told how to use it.
      class Skill < Thor::Group
        include Thor::Actions

        argument :name, type: :string, desc: "The skill's name, in kebab-case"

        class_option :gem, type: :string,
                           desc: "Which gem, in a repository holding more than one gemspec"
        class_option :dir, type: :string, default: ".agents/skills",
                           desc: "Where skills live in this project"

        add_runtime_options!

        def self.source_root = File.expand_path("templates", __dir__)

        def self.banner = "gem kit skill NAME"

        def skill_document
          template("SKILL.md.erb", File.join(destination, "SKILL.md"))
        end

        def what_next
          say ""
          say "Written to #{destination}. Fill in the sections marked TODO —"
          say "a skill an agent cannot act on is worse than no skill at all."
        end

        no_commands do
          def destination
            File.join(project.root, options[:dir], name)
          end

          # Values the template renders against.
          def gem_name    = project.name
          def gem_version = project.version.to_s
          def summary     = project.spec.summary.to_s
          def homepage    = project.spec.homepage.to_s
          def require_path = project.require_path

          def project
            @project ||= GemKit::Release::Project.detect(Dir.pwd, name: options[:gem])
          rescue GemKit::Release::Project::NotFound, GemKit::Release::Project::Ambiguous => error
            raise GemKit::Release::Failure, error.message
          end
        end
      end
    end
  end
end

__END__

describe "gem_kit/plugin/generators/skill" do
  require_relative "../../../../spec/support/gem_kit_plugin_spec"
  extend GemKitPluginSpec

  it "writes a SKILL.md under the skills directory" do
    with_gem(complete: true) do |dir|
      status, out, _err = invoke(["skill", "using-demo"], dir)

      status.should == 0
      out.should.match(/create.*SKILL\.md/)
      File.exist?(File.join(dir, ".agents/skills/using-demo/SKILL.md")).should.be.true
    end
  end

  it "fills the frontmatter in from the gemspec" do
    with_gem(complete: true) do |dir|
      invoke(["skill", "using-demo"], dir)

      skill = File.read(File.join(dir, ".agents/skills/using-demo/SKILL.md"))
      skill.should.match(/^name: using-demo$/)
      skill.should.match(/demo/)
      skill.should.match(/require "demo"/)
      skill.should.not.match(/<%=/)
    end
  end

  it "honours --dir" do
    with_gem(complete: true) do |dir|
      invoke(["skill", "using-demo", "--dir", "skills"], dir)
      File.exist?(File.join(dir, "skills/using-demo/SKILL.md")).should.be.true
    end
  end

  it "reports an unchanged skill as identical" do
    with_gem(complete: true) do |dir|
      invoke(["skill", "using-demo"], dir)

      _status, out, _err = invoke(["skill", "using-demo"], dir)
      out.should.match(/identical.*SKILL\.md/)
    end
  end

  it "--pretend writes nothing" do
    with_gem(complete: true) do |dir|
      invoke(["skill", "using-demo", "--pretend"], dir).first.should == 0
      File.exist?(File.join(dir, ".agents/skills/using-demo/SKILL.md")).should.be.false
    end
  end

  it "requires a name" do
    with_gem(complete: true) do |dir|
      invoke(["skill"], dir).first.should.not == 0
    end
  end
end
