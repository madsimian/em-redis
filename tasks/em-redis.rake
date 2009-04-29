namespace :redis do
  desc "Test em-redis against a live Redis"
  task :live_test do
    require 'bacon'
    sh "bacon spec/live_redis_protocol_spec.rb"
  end

  desc "Test em-redis offline"
  task :offline_test do
    sh "bacon spec/redis_protocol_spec.rb"
  end
end
