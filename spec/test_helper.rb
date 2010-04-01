require File.expand_path(File.dirname(__FILE__) + "/../lib/em-redis")
require 'bacon'
require 'em-spec/bacon'

EM.spec_backend = EventMachine::Spec::Bacon

class TestConnection
  include EM::P::Redis

  def send_data data
    sent_data << data
  end

  def sent_data
    @sent_data ||= ''
  end

  def initialize
    super
    connection_completed
  end
end
