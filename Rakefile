require 'rake'
require 'spec/rake/spectask'

desc "Run all specs"
Spec::Rake::SpecTask.new('spec') do |t|
	t.spec_files = FileList['spec/*_spec.rb']
end

task :default => :spec

#################

require 'rake'
require 'rake/testtask'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'fileutils'
include FileUtils

version = "0.1"
name = "yaml_db"

spec = Gem::Specification.new do |s|
	s.name = name
	s.version = version
	s.summary = "database-independent utility to dump and restore data from ActiveRecord"
	s.author = "Adam Wiggins"
	s.email = "feedback@heroku.com"
	s.homepage = "http://heroku.com/"
	s.executables = [ "yamldb" ]
	s.default_executable = "yamldb"

	s.platform = Gem::Platform::RUBY
	s.has_rdoc = true

	s.files = %w(Rakefile) +
		Dir.glob("{bin,lib,spec,tasks}/**/*")

	s.require_path = "lib"
	s.bindir = "bin"                               # Use these for applications.
end

Rake::GemPackageTask.new(spec) do |p|
	p.need_tar = true if RUBY_PLATFORM !~ /mswin/
end

task :install => [ :package ] do
	sh %{sudo gem install pkg/#{name}-#{version}.gem}
end

task :uninstall => [ :clean ] do
	sh %{sudo gem uninstall #{name}}
end
