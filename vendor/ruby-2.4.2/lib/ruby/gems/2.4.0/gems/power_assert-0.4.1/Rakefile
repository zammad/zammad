require "bundler/gem_tasks"

require "rake/testtask"
task :default => :test
Rake::TestTask.new do |t|
  # helper(simplecov) must be required before loading power_assert
  t.ruby_opts = ["-w", "-r./test/helper"]
  t.test_files = FileList["test/test_*.rb"]
end

desc "Run the benchmark suite"
task('benchmark') do
  Dir.glob('benchmarks/bm_*.rb').each do |f|
    load(f)
  end
end
