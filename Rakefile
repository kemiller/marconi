require 'rubygems/package_task'
require 'rake/testtask'
require 'pp'

task :default => [:test]

desc 'Tests'
Rake::TestTask.new(:test) do |t|
        t.libs << "test"
        t.test_files = Dir.glob("test/**/test_*.rb")
        t.verbose = true
end

spec = Gem::Specification.load(Dir['*.gemspec'].first)
gem = Gem::PackageTask.new(spec)
gem.define

desc "Push gem to rubygems.org"
task :push => :gem do
	pp gem
  sh "gem push #{gem.package_dir}/#{gem.name}.gem"
end

