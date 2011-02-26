ENV["WATCHR"] = "1"

def say(message)
  passed = message.include?('0 failures, 0 errors')
  statements = message.split(',')
  error_message = statements[3] + ' and ' + statements[2]
  system %(say #{passed ? 'Success!' : error_message})
end

def growl(message)
  growlnotify = `which growlnotify`.chomp
  title = "Watchr Test Results"
  passed = message.include?('0 failures, 0 errors')
  image = passed ? "~/bin/watchr/images/passed.png" : "~/bin/watchr/images/failed.png"
  options = "-w -n Watchr --image '#{File.expand_path(image)}' -m '#{message}' '#{title}'"
  system %(#{growlnotify} #{options} &)
  # say message
end

def run(cmd)
  puts(cmd)
  `#{cmd}`
end

def run_spec(file)
  system('clear')
  unless File.exist?(file)
    puts "#{file} does not exist"
    return
  end
  puts "Running #{file}"
  result = run("bundle exec rspec #{file}")
  growl result.split("\n").last rescue nil
  puts result
end

watch("spec/.*/*_spec\.rb") do |match|
  run_spec match[0]
end

watch("app/(.*/.*)\.rb") do |match|
  run_spec %{spec/#{match[1]}_spec.rb}
end

def run_all_specs
  system('clear')
  result = run "rake spec"
  growl result.split("\n").last rescue nil
  puts result
end

def run_spec(file)
  unless File.exist?(file)
    puts "#{file} does not exist"
    return
  end
  puts "Running #{file}"
  system "bundle exec rspec #{file}"
  puts
end

watch("spec/.*/*_spec\.rb") do |match|
  run_spec match[0]
end

watch("app/(.*/.*)\.rb") do |match|
  run_spec %{spec/#{match[1]}_spec.rb}
end

watch('spec/spec_helper\.rb') { run_all_tests }

# Ctrl-\
Signal.trap 'QUIT' do
  puts " --- Running all tests ---\n\n"
  run_all_specs
end

@interrupted = false

# Ctrl-C
Signal.trap 'INT' do
  if @interrupted then
    @wants_to_quit = true
    abort("\n")
  else
    puts "Interrupt a second time to quit"
    @interrupted = true
    Kernel.sleep 1.5
    # raise Interrupt, nil # let the run loop catch it
    run_all_specs
  end
end
