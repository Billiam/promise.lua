task :default => :busted

desc "Run lua tests"
task :busted do
  File.delete('luacov.stats.out') if File.exists?('luacov.stats.out')
  system('busted -c spec')
  `luacov -c=spec/.luacov`
end