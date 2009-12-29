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

task :default => ['redis:live_test', 'redis:offline_test']

Bones {
  name 'em-redis'
  authors ['Jonathan Broad', 'Eugene Pimenov']
  email 'libc@me.com'
  url ''
  version EMRedis::VERSION

  readme_file  'README.rdoc'
  ignore_file  '.gitignore'

  depend_on 'eventmachine', '>=0.12.10'

  depend_on "bacon", :development => true
  depend_on "em-spec", :development => true 
}

# EOF
