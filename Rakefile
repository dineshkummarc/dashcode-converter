require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "dashcode-converter"
    gem.summary = "Tool to convert Apple Dashcode projects into Coherent NIBs"
    gem.description = ""
    gem.email = "jeff@metrocat.org"
    gem.homepage = "http://github.com/jeffwatkins/dashcode-converter"
    gem.authors = ["Jeff Watkins"]
    gem.add_dependency('json', '>= 1.4.3')
    gem.add_dependency('nokogiri', '>=1.4.3.1')
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

# require 'rake/testtask'
# Rake::TestTask.new(:test) do |test|
#   test.libs << 'lib' << 'test'
#   test.pattern = 'test/**/test_*.rb'
#   test.verbose = true
# end
# 
# begin
#   require 'rcov/rcovtask'
#   Rcov::RcovTask.new do |test|
#     test.libs << 'test'
#     test.pattern = 'test/**/test_*.rb'
#     test.verbose = true
#   end
# rescue LoadError
#   task :rcov do
#     abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
#   end
# end

task :push => "gemcutter:release"

task :test => :check_dependencies

task :default => :build

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "dashcode-converter #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
