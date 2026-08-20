# frozen_string_literal: true

require_relative "support/gem_kit_plugin_spec"

__END__

describe "gem_kit/plugin" do
  extend GemKitPluginSpec

  it "adds `gem kit plugin`, which prints its page" do
    with_gem do |dir|
      status, out, _err = invoke(["plugin"], dir)

      status.should == 0
      out.should.match(/You are looking at a command that came from a different gem/)
      out.should.match(/lib\/rubygems_plugin\.rb/)
    end
  end

  # The point of the example: a plugin command is not second-class.
  it "is listed by `gem kit` alongside the built-in commands" do
    with_gem do |dir|
      _status, out, _err = invoke([], dir)

      out.should.match(/gem kit plugin/)
      out.should.match(/gem kit bump/)
    end
  end

  it "has a help page like any other command" do
    with_gem do |dir|
      _status, out, _err = invoke(["help", "plugin"], dir)

      out.should.match(/gem kit plugin/)
      out.should.match(/GemKit::Release\.plugin do/)
    end
  end

  it "is loaded by lib/rubygems_plugin.rb, which is how RubyGems finds it" do
    plugin_file = File.expand_path("../lib/rubygems_plugin.rb", __dir__)

    File.exist?(plugin_file).should.be.true
    File.read(plugin_file).should.match(/require_relative "gem_kit\/plugin"/)
  end
end
