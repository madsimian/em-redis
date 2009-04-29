require File.expand_path(File.dirname(__FILE__) + "/../lib/em-redis")
require 'em/spec'

class TestConnection
  include EM::P::Redis
  def send_data data
    sent_data << data
  end
  def sent_data
    @sent_data ||= ''
  end

  def initialize
    connection_completed
  end
end
