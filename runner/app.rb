require 'fileutils'
require 'tmpdir'

problems = Dir.entries(File.expand_path("../problemsF", __dir__)).map do |file|
  File.expand_path("../problemsF/#{file}", __dir__)
end

assemble_problems = problems.select { |name| name =~ /tgt\.mdl/ }
#chunked_assemblies = assemble_problems.each_slice(8)

Dir.chdir(File.expand_path("../nanobots", __dir__)) do
  `mix escript.build`
end


assemble_problems.each do |problem|
  puts `#{File.expand_path("../nanobots/nanobots", __dir__)} #{problem}`
end

#chunked_assemblies.each do |group|
#  group.map do |location, acc|
#    Thread.new { puts system("#{File.expand_path("../nanobots/nanobots", __dir__)} #{location}") }
#  end.each { |thread| thread.join }
#end

if SYSTEM_RUBY.contains('darwin')
  traces = Dir.entries(File.expand_path("../problemsF", __dir__)).map do |file|
    File.expand_path("../problemsF/#{file}", __dir__)
  end.select { |file| file =~ /\.nbt/ }

  tmp_dir = Dir.mktmpdir('traces')
  FileUtils.cp(traces, tmp_dir)
  `zip -r traces.zip #{tmp_dir}`
end
