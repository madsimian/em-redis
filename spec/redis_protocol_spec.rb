require File.expand_path(File.dirname(__FILE__) + "/test_helper.rb")

EM.describe EM::Protocols::Redis do
  default_timeout 1

  before do
    @c = TestConnection.new
  end

  # Inline request protocol
  should 'send inline commands correctly' do
    @c.call_command(["GET", 'a'])
    @c.sent_data.should == "*2\r\n$3\r\nget\r\n$1\r\na\r\n"
    done
  end

  should "space-separate multiple inline arguments" do
    @c.call_command(["GET", 'a', 'b', 'c'])
    @c.sent_data.should == "*4\r\n$3\r\nget\r\n$1\r\na\r\n$1\r\nb\r\n$1\r\nc\r\n"
    done
  end

  # Multiline request protocol
  should "send multiline commands correctly" do
    @c.call_command(["SET", "foo", "abc"])
    @c.sent_data.should == "*3\r\n$3\r\nset\r\n$3\r\nfoo\r\n$3\r\nabc\r\n"
    done
  end

  should "send integers in multiline commands correctly" do
    @c.call_command(["SET", "foo", 1_000_000])
    @c.sent_data.should == "*3\r\n$3\r\nset\r\n$3\r\nfoo\r\n$7\r\n1000000\r\n"
    done
  end

  # Specific calls
  #
  # SORT
  should "send sort command" do
    @c.sort "foo"
    @c.sent_data.should == "*2\r\n$4\r\nsort\r\n$3\r\nfoo\r\n"
    done
  end

  should "send sort command with all optional parameters" do
    @c.sort "foo", :by => "foo_sort_*", :get => "data_*", :order => "DESC ALPHA", :limit => [0, 10]
    expected = "*11\r\n$4\r\nsort\r\n$3\r\nfoo\r\n$2\r\nby\r\n$10\r\nfoo_sort_*\r\n$3\r\nget\r\n"
    expected += "$6\r\ndata_*\r\n$4\r\nDESC\r\n$5\r\nALPHA\r\n$5\r\nlimit\r\n$1\r\n0\r\n$2\r\n10\r\n"
    @c.sent_data.should == expected
    done
  end

  should "parse keys response into an array" do
    @c.keys("*") do |resp|
      resp.should == ["a","b","c"]
      done
    end
    @c.receive_data "*3\r\n$1\r\na\r\n$1\r\nb\r\n$1\r\nc\r\n"
  end


  # Inline response
  should "parse an inline response" do
    @c.call_command(["PING"]) do |resp|
      resp.should == "OK"
      done
    end
    @c.receive_data "+OK\r\n"
  end

  should "parse an inline integer response" do
    @c.call_command(["integer"]) do |resp|
      resp.should == 0
      done
    end
    @c.receive_data ":0\r\n"
  end

  should "call processor if any" do
    @c.call_command(["EXISTS"]) do |resp|
      resp.should == false
      done
    end
    @c.receive_data ":0\r\n"
  end

  should "trigger a given error callback (specified with on_error) for inline error response instead of raising an error" do
    lambda do
      @c.call_command(["blarg"])
      @c.on_error {|err| err.code.should == "ERR"; done }
      @c.receive_data "-ERR\r\n"
    end.should.not.raise(EM::P::Redis::RedisError)
  end

  should "trigger a given error callback for inline error response instead of raising an error" do
    lambda do
      @c.call_command(["blarg"])
      @c.errback { |err| err.code.should == "ERR"; done }
      @c.receive_data "-ERR\r\n"
    end.should.not.raise(EM::P::Redis::RedisError)
  end

  # Bulk response
  should "parse a bulk response" do
    @c.call_command(["GET", "foo"]) do |resp|
      resp.should == "bar"
      done
    end
    @c.receive_data "$3\r\n"
    @c.receive_data "bar\r\n"
  end

  should "distinguish nil in a bulk response" do
    @c.call_command(["GET", "bar"]) do |resp|
      resp.should == nil
      done
    end
    @c.receive_data "$-1\r\n"
  end

  # Multi-bulk response
  should "parse a multi-bulk response" do
    @c.call_command(["RANGE", 0, 10]) do |resp|
      resp.should == ["a", "b", "foo"]
      done
    end
    @c.receive_data "*3\r\n"
    @c.receive_data "$1\r\na\r\n"
    @c.receive_data "$1\r\nb\r\n"
    @c.receive_data "$3\r\nfoo\r\n"
  end

  should "distinguish nil in a multi-bulk response" do
    @c.call_command(["RANGE", 0, 10]) do |resp|
      resp.should == ["a", nil, "foo"]
      done
    end
    @c.receive_data "*3\r\n"
    @c.receive_data "$1\r\na\r\n"
    @c.receive_data "$-1\r\n"
    @c.receive_data "$3\r\nfoo\r\n"
  end
end
