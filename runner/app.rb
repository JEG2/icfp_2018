problem_directory_files = Dir.entries(File.expand_path("../problemsF", __dir__))
problems = problem_directory_files.map do |file|
  File.expand_path("../problemsF/#{file}", __dir__)
end

assemble_problems = problems.select { |name| name =~ /tgt\.mdl/ }
chunked_assemblies = assemble_problems.each_slice(8)

Dir.chdir(File.expand_path("../nanobots", __dir__)) do
  `mix escript.build`
end

chunked_assemblies.each do |group|
  group.map do |location, acc|
    Thread.new { puts `#{File.expand_path("../nanobots/nanobots", __dir__)} #{location}` }
  end.each { |thread| thread.join }
end
