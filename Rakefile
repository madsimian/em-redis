# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

begin
  require 'bones'
rescue LoadError
  abort '### Please install the "bones" gem ###'
end

ensure_in_path 'lib'
require 'em-redis'

task :default => ['redis:test']

Bones {
  name 'em-redis'
  authors ['Jonathan Broad', 'Eugene Pimenov']
  email 'libc@me.com'
  url 'http://github.com/libc/em-redis'
  summary 'An eventmachine-based implementation of the Redis protocol'
  description summary
  version EMRedis::VERSION

  readme_file  'README.rdoc'
  ignore_file  '.gitignore'

  depend_on 'eventmachine', '>=0.12.10'

  depend_on "bacon", :development => true
  depend_on "em-spec", :development => true 
}

namespace :redis do
  desc "Test em-redis against a live Redis"
  task :test do
    sh "bacon spec/live_redis_protocol_spec.rb spec/redis_commands_spec.rb spec/redis_protocol_spec.rb"
  end
end

# EOF
