require 'rake/testtask'
require 'coveralls/rake/task'

task default: %w[test]

Rake::TestTask.new do |t|
  t.libs.push 'lib', 'test'
  t.test_files = FileList['test/test_*.rb']
  t.verbose = true
end

Coveralls::RakeTask.new
