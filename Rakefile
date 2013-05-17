require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :spec do
  desc "run just tasks flagged for perf checks"
  RSpec::Core::RakeTask.new(:perf) do |t|
    t.rspec_opts = ['--tag perf', '--profile']
  end
end
