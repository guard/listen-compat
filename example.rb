require 'listen/compat/wrapper'

listener = Listen::Compat::Wrapper.create

directories = %w(lib pkg spec)
options = { force_polling: false }

listener.listen(directories, options) do |modified, added, removed|
  puts "Modified: #{modified.inspect}"
  puts "Added: #{added.inspect}"
  puts "Removed: #{removed.inspect}"
end
