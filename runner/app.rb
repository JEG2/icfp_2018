require 'fileutils'

def move_tracer(filename)
  tracer = filename.sub('.mdl', '.nbt')
  dest   = File.expand_path("problems/#{tracer}", __dir__)
  # uncomment to run once bot runner is finished
  # FileUtils.mv(tracer, dest)
end

temp_file = File.new(__dir__ + "/temp.txt", "w")
results_file_path = __dir__ + "/results.txt"
`touch #{results_file_path}`

problem_directory_files = Dir.entries(File.expand_path("problems", __dir__))[2..-1]
problems = problem_directory_files.select { |filename|  filename =~ /.+\.mdl/}

new_scores = Dir.chdir(File.expand_path("../nanobots", __dir__)) do
  problems.reduce({}) do |acc, name|
    score = `echo '12345'`
    # Uncomment and delete line above once bot runner is finished
    # score = `mix run`
    acc[name] = score.to_i
    acc
  end
end

existing_file = File.new(results_file_path, 'r')
existing_scores = existing_file.reduce({}) do |acc, line|
  line_data      = line.split(",")
  name           = line_data[0]
  score          = line_data[1].to_i
  acc[name]      = score.to_i
  acc
end

new_scores.each do |filename, score|
  if score < (existing_scores[filename] || Float::INFINITY)
    move_tracer(filename)
    temp_file.puts(filename + ',' + new_scores[filename].to_s)
  else
    temp_file.puts(filename + ',' + existing_scores[filename].to_s)
  end
end

FileUtils.mv(temp_file.path, results_file_path)

