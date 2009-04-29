require 'rubygems'
require 'eventmachine'

module EventMachine
  module Protocols
    module Redis
      include EM::Deferrable

      ##
      # constants
      #########################

      unless defined? C_ERR
        C_ERR = "-".freeze
        C_OK = 'OK'.freeze
        C_SINGLE = '+'.freeze
        C_BULK   = '$'.freeze
        C_MULTI  = '*'.freeze
        C_INT    = ':'.freeze
        C_DELIM  = "\r\n".freeze
      end

      #QUIT, AUTH (NOT IMPLEMENTED) 
      def quit(&blk)
        inline_command "QUIT", &blk
      end
      
      #GET,SET,MGET,SETNX,INCR,INCRBY,DECR,DECRBY,EXISTS,DEL,TYPE
      def type(key, &blk)
        inline_command "TYPE", key, &blk 
      end

      def del(key, &blk)
        inline_command "DEL", key, &blk
      end

      def exists(key, &blk)
        inline_command "EXISTS", key, &blk
      end

      def decrby(key, value, &blk)
        inline_command "DECRBY", key, value, &blk
      end

      def decr(key, &blk)
        inline_command "DECR", key, &blk
      end

      def incrby(key, value, &blk)
        inline_command "INCRBY", key, value, &blk
      end

      def incr(key, &blk)
        inline_command "INCR", key, &blk
      end

      def setnx(key, value, &blk)
        multiline_command "SETNX", key, value, &blk
      end

      def mget(*keys, &blk)
        inline_command "MGET", *keys, &blk
      end

      def set(key, value, &blk)
        multiline_command "SET", key, value, &blk
      end

      def get(key, &blk)
        inline_command "GET", key, &blk
      end
      
      #KEYS,RANDOMKEY,RENAME,RENAMENX,DBSIZE,EXPIRE
      def keys(key_search_string, &blk)
        wrapper = lambda {|v| blk.call(v.split)} # spec suggests splitting response on whitespace
        inline_command "KEYS", key_search_string, &wrapper
      end

      def randomkey(&blk)
        inline_command "RANDOMKEY", &blk
      end

      def rename(old_name, new_name, &blk)
        inline_command "RENAME", old_name, new_name, &blk
      end

      def renamenx(old_name, new_name, &blk)
        inline_command "RENAMENX", old_name, new_name, &blk
      end

      def dbsize(&blk)
        inline_command "DBSIZE", &blk
      end

      def expire(key, &blk)
        inline_command "EXPIRE", key, &blk
      end
      
      #RPUSH,LPUSH,LLEN,LRANGE,LTRIM,LINDEX,LSET,LREM,LPOP,RPOP
      def rpop(key, &blk)
        inline_command "RPOP", key, &blk
      end

      def lpop(key, &blk)
        inline_command "LPOP", key, &blk
      end

      def lrem(key, value, count=0, &blk)
        multiline_command "LREM", key, count, value, &blk
      end

      def lset(key, index, value, &blk)
        multiline_command "LSET", key, index, value, &blk
      end

      def lindex(key, index, &blk)
        inline_command "LINDEX", key, index, &blk
      end

      def ltrim(key, start, ending, &blk)
        inline_command "LTRIM", key, start, ending, &blk
      end

      def lrange(key, start, range, &blk)
        inline_command "LRANGE", key, start, range, &blk
      end

      def llen(key, &blk)
        inline_command "LLEN", key, &blk
      end

      def lpush(key, value, &blk)
        multiline_command "LPUSH", key, value, &blk
      end

      def rpush(key, value, &blk)
        multiline_command "RPUSH", key, value, &blk
      end

      
      
      #SADD,SREM,SCARD,SISMEMBER,SINTER,SINTERSTORE,SUNION,SUNIONSTORE,SMEMBERS
      def sadd(key, value, &blk)
        multiline_command "SADD", key, value, &blk
      end

      def srem(key, value, &blk)
        multiline_command "SREM", key, value, &blk
      end

      def scard(key, &blk)
        inline_command "SCARD", key, &blk
      end

      def sismember(key, value, &blk)
        multiline_command "SISMEMBER", key, value, &blk
      end

      def sinter(*keys, &blk)
        inline_command "SINTER", *keys, &blk
      end

      def sinterstore(target_key, *keys, &blk)
        inline_command "SINTERSTORE", target_key, *keys, &blk
      end

   #  UNION SET MANIP NOT IN RELEASE BUILDS YET
   ############################################
   #  
   #  def sunion(*keys, &blk)
   #    inline_command "SUNION", *keys, &blk
   #  end
   #
   #  def sunionstore(target_key, *keys, &blk)
   #    inline_command "SUNIONSTORE", target_key, *keys, &blk
   #  end
   #  
   ############################################

      def smembers(key, &blk)
        inline_command "SMEMBERS", key, &blk
      end

      
      #SELECT,MOVE,FLUSHDB,FLUSHALL
      def select(db_index, &blk)
        inline_command "SELECT", db_index, &blk
      end

      def move(key, dbindex, &blk)
        inline_command "MOVE", key, dbindex, &blk
      end

      def flushdb(&blk)
        inline_command "FLUSHDB", &blk
      end

      def flushall(&blk)
        inline_command "FLUSHALL", &blk
      end

      #SORT
      def sort(key, by_pattern=nil, start=nil, ending=nil, get_pattern=nil, desc=false, alpha=false, &blk)
        command = "SORT #{key}"
        command += " BY #{by_pattern}" if by_pattern
        command += " LIMIT #{start} #{ending}" if (start && ending)
        command += " GET #{get_pattern}" if get_pattern
        command += " DESC" if desc
        command += " ALPHA" if alpha
        inline_command command, &blk
      end
      
      #SAVE,BGSAVE,LASTSAVE,SHUTDOWN
      def shutdown(&blk)
        inline_command "SHUTDOWN", &blk
      end

      def lastsave(&blk)
        inline_command "LASTSAVE", &blk
      end

      def bgsave(&blk)
        inline_command "BGSAVE", &blk
      end

      def save(&blk)
        inline_command "SAVE", &blk
      end

      #INFO,MONITOR
      def info(&blk)
        wrapper = lambda do |r| 
          blk.call(
            r.split.inject({}) {|hash,string| key,value = string.split(":"); hash[key] = value; hash }
          )
        end
        inline_command "INFO", &wrapper
      end

      def on_error(&blk)
        @err_cb = blk
      end
      
      # MONITOR's a bit tricky
      def monitor
      end

      ## 
      # Generic request methods      
      #########################

      def inline_command(*args, &blk)
        callback {
          command = args.shift
          blk ||= lambda { } # all cmds must at least have a no-op callback
          @cbs << blk 
          if args.size > 0
            command += " " 
            command += args.join(" ")
          end
          command += C_DELIM
          puts "*** sending: #{command}" if $debug
          send_data command
        }
      end

      def multiline_command(command, *args, &blk)
        callback {
          data_value = args.pop
          blk ||= lambda { } # all cmds must at least have a no-op callback
          @cbs << blk 
          command += " "
          if args.size > 0
            command += args.join(" ") 
            command += " "
          end
          command += data_value.size.to_s
          command += C_DELIM
          command += data_value.to_s
          command += C_DELIM
          puts "*** sending: #{command}" if $debug
          send_data command
        }
      end

      
      ##
      # errors
      #########################

      class ParserError < StandardError; end

      class RedisError < StandardError
        attr_accessor :code
      end


      ##
      # em hooks
      #########################

      def self.connect host = 'localhost', port = 6379 
        puts "*** connecting" if $debug
        EM.connect host, port, self, host, port
      end

      def initialize host, port = 6379 
        puts "*** initializing" if $debug
        @host, @port = host, port
      end

      def connection_completed
        puts "*** connection_complete!" if $debug
        @cbs = []
        @values = []
        @multi_n = 0

        @reconnecting = false
        @connected = true
        succeed
      end

      # 19Feb09 Switched to a custom parser, LineText2 is recursive and can cause
      #         stack overflows when there is too much data.
      # include EM::P::LineText2
      def receive_data data
        (@buffer||='') << data
        while index = @buffer.index(C_DELIM)
          begin
            line = @buffer.slice!(0,index+2)
            process_cmd line
          rescue ParserError
            @buffer[0...0] = line
            break
          end
        end
      end

      def process_cmd line
        puts "*** processing #{line}" if $debug
        case line[0].chr
        when C_SINGLE
          if cb = @cbs.shift
            cb.call(line.slice(1..-3))
          end
        when C_BULK
          len = Integer(line.slice(1..-3))
          if len == -1
            if @multi_n > 0
              @values << nil
              if @values.size == @multi_n
                if cb = @cbs.shift
                  cb.call(@values)
                  @values = []
                  @multi_n = 0
                end
              end
            else
              if cb = @cbs.shift
                cb.call(nil)
              end
            end
            return
          end
          if @buffer.size >= len + 2
            if @multi_n > 0
              @values << @buffer.slice!(0,len)
              if @values.size == @multi_n
                if cb = @cbs.shift
                  cb.call(@values)
                  @values = []
                  @multi_n = 0
                end
              end
              @buffer.slice!(0,2)
            else
              value = @buffer.slice!(0,len)
              if cb = @cbs.shift
                cb.call(value)
              end
              @buffer.slice!(0,2)
            end
          else
            raise ParserError
          end
        when C_INT
          if cb = @cbs.shift
            cb.call( Integer(line.slice(1..-3)) )
          end
        when C_MULTI
          @multi_n = Integer(line.slice(1..-3))
          if @multi_n == -1
            if cb = @cbs.shift
              cb.call(nil)
            end
          end
        when C_ERR
          code = line.slice(1..-3)
          @cbs.shift # throw away the cb?
          if @err_cb
            @err_cb.call(code)
          else
            err = RedisError.new
            err.code = code
            raise err, "Redis server returned error code: #{code}"
          end
        else
          p 'other'
        end
      end

      def unbind
        puts "*** unbinding" if $debug
        if @connected or @reconnecting
          EM.add_timer(1){ reconnect @host, @port }
          @connected = false
          @reconnecting = true
          @deferred_status = nil
        else
          raise 'Unable to connect to memcached server'
        end
      end

    end
  end
end

if __FILE__ == $0
  # ruby -I ext:lib -r eventmachine -rubygems lib/protocols/memcache.rb
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


  EM.describe EM::Protocols::Redis do

    before do
      @c = TestConnection.new
    end

    # Inline request protocol
    should 'send inline commands correctly' do
      @c.inline_command("GET", 'a')
      @c.sent_data.should == "GET a\r\n"
      done
    end
    
    should "space-separate multiple inline arguments" do
      @c.inline_command("GET", 'a', 'b', 'c')
      @c.sent_data.should == "GET a b c\r\n"
      done
    end

    # Multiline request protocol
    should "send multiline commands correctly" do
      @c.multiline_command("SET", "foo", "abc")
      @c.sent_data.should == "SET foo 3\r\nabc\r\n"
      done
    end

    # Specific calls
    #
    # SORT
    should "send sort command" do
      @c.sort "foo"
      @c.sent_data.should == "SORT foo\r\n"
      done
    end

    should "send sort command with all optional parameters" do
      @c.sort "foo", "foo_sort_*", 0, 10, "data_*", true, true
      @c.sent_data.should == "SORT foo BY foo_sort_* LIMIT 0 10 GET data_* DESC ALPHA\r\n"
      done
    end

    # Inline response
    should "parse an inline response" do
      @c.inline_command("PING") do |resp|
        resp.should == "OK"
        done
      end
      @c.receive_data "+OK\r\n"
    end

    should "parse an inline integer response" do
      @c.inline_command("EXISTS") do |resp|
        resp.should == 0
        done
      end
      @c.receive_data ":0\r\n"
    end

    should "parse an inline error response" do
      lambda do
        @c.inline_command("BLARG")
        @c.receive_data "-FAIL\r\n"
      end.should.raise(EM::P::Redis::RedisError)
      done
    end

    should "trigger a given error callback for inline error response instead of raising an error" do
      lambda do
        @c.inline_command("BLARG")
        @c.on_error {|code| code.should == "FAIL"; done }
        @c.receive_data "-FAIL\r\n"
      end.should.not.raise(EM::P::Redis::RedisError)
      done
    end

    # Bulk response
    should "parse a bulk response" do
      @c.inline_command("GET", "foo") do |resp|
        resp.should == "bar"
        done
      end
      @c.receive_data "$3\r\n"
      @c.receive_data "bar\r\n"
    end

    should "distinguish nil in a bulk response" do
      @c.inline_command("GET", "bar") do |resp|
        resp.should == nil
      end
      @c.receive_data "$-1\r\n"
    end
    
    # Multi-bulk response
    
    should "parse a multi-bulk response" do
      @c.inline_command "RANGE", 0, 10 do |resp|
        resp.should == ["a", "b", "foo"]
        done
      end
      @c.receive_data "*3\r\n"
      @c.receive_data "$1\r\na\r\n"
      @c.receive_data "$1\r\nb\r\n"
      @c.receive_data "$3\r\nfoo\r\n"
    end

    should "distinguish nil in a multi-bulk response" do
      @c.inline_command "RANGE", 0, 10 do |resp|
        resp.should == ["a", nil, "foo"]
        done
      end
      @c.receive_data "*3\r\n"
      @c.receive_data "$1\r\na\r\n"
      @c.receive_data "$-1\r\n"
      @c.receive_data "$3\r\nfoo\r\n"
    end
  end
end
