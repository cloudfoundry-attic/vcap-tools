require "bundler"
require "rspec/core/rake_task"

ENV["BUNDLE_GEMFILE"] = "Gemfile"

RSpec::Core::RakeTask.new("spec") do |t|
  t.rspec_opts = ["--format", "documentation", "--colour"]
  t.pattern    = "spec/unit/**/*_spec.rb"
end

task :default => :spec

if RUBY_VERSION < "1.9"
  desc "Run spec with coverage"
  RSpec::Core::RakeTask.new(:coverage => :cleanup_coverage) do |task|
    task.rcov = true
    task.rcov_opts =  %[-Ilib -Ispec --exclude "gems/*,spec/unit,spec/spec_helper.rb"]
  end
else
  desc "Run spec with coverage"
  task :coverage => :cleanup_coverage do
    require "simplecov"

    SimpleCov.start do
      add_filter "/spec/"

      require "rspec/core"
      spec_dir = File.expand_path("../spec", __FILE__)
      RSpec::Core::Runner.disable_autorun!
      RSpec::Core::Runner.run [spec_dir], STDERR, STDOUT
    end

  end
end

desc "Cleanup coverage"
task :cleanup_coverage do
  rm_rf "coverage"
end
