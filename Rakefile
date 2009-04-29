# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

begin
  require 'bones'
  Bones.setup
rescue LoadError
  load 'tasks/setup.rb'
end

ensure_in_path 'lib'
require 'em-redis'

task :default => 'spec:run'

PROJ.name = 'em-redis'
PROJ.authors = 'Jonathan Broad'
PROJ.email = 'jonathan@relativepath.org'
PROJ.url = ''
PROJ.version = EMRedis::VERSION
PROJ.rubyforge.name = 'em-redis'
PROJ.spec.opts << '--color'
PROJ.gem.dependencies << "bacon"

# EOF
