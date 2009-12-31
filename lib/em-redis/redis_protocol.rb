require 'rubygems'
require 'eventmachine'

module EventMachine
  module Protocols
    module Redis
      include EM::Deferrable

      ##
      # constants
      #########################

      OK      = "OK".freeze
      MINUS    = "-".freeze
      PLUS     = "+".freeze
      COLON    = ":".freeze
      DOLLAR   = "$".freeze
      ASTERISK = "*".freeze
      DELIM    = "\r\n".freeze

      BULK_COMMANDS = {
        "set"       => true,
        "setnx"     => true,
        "rpush"     => true,
        "lpush"     => true,
        "lset"      => true,
        "lrem"      => true,
        "sadd"      => true,
        "srem"      => true,
        "sismember" => true,
        "rpoplpush" => true,
        "echo"      => true,
        "getset"    => true,
        "smove"     => true,
        "zadd"      => true,
        "zincrby"   => true,
        "zrem"      => true,
        "zscore"    => true
      }

      MULTI_BULK_COMMANDS = {
        "mset"      => true,
        "msetnx"    => true,
        # these aliases aren't in redis gem
        "multi_get" => true
      }

      BOOLEAN_PROCESSOR = lambda{|r| r == 1 }

      REPLY_PROCESSOR = {
        "exists"    => BOOLEAN_PROCESSOR,
        "sismember" => BOOLEAN_PROCESSOR,
        "sadd"      => BOOLEAN_PROCESSOR,
        "srem"      => BOOLEAN_PROCESSOR,
        "smove"     => BOOLEAN_PROCESSOR,
        "zadd"      => BOOLEAN_PROCESSOR,
        "zrem"      => BOOLEAN_PROCESSOR,
        "move"      => BOOLEAN_PROCESSOR,
        "setnx"     => BOOLEAN_PROCESSOR,
        "del"       => BOOLEAN_PROCESSOR,
        "renamenx"  => BOOLEAN_PROCESSOR,
        "expire"    => BOOLEAN_PROCESSOR,
        "select"    => BOOLEAN_PROCESSOR, # not in redis gem
        "keys"      => lambda{|r| r.split(" ")},
        "info"      => lambda{|r|
          info = {}
          r.each_line {|kv|
            k,v = kv.split(":",2).map{|x| x.chomp}
            info[k.to_sym] = v
          }
          info
        }
      }

      ALIASES = {
        "flush_db"             => "flushdb",
        "flush_all"            => "flushall",
        "last_save"            => "lastsave",
        "key?"                 => "exists",
        "delete"               => "del",
        "randkey"              => "randomkey",
        "list_length"          => "llen",
        "push_tail"            => "rpush",
        "push_head"            => "lpush",
        "pop_tail"             => "rpop",
        "pop_head"             => "lpop",
        "list_set"             => "lset",
        "list_range"           => "lrange",
        "list_trim"            => "ltrim",
        "list_index"           => "lindex",
        "list_rm"              => "lrem",
        "set_add"              => "sadd",
        "set_delete"           => "srem",
        "set_count"            => "scard",
        "set_member?"          => "sismember",
        "set_members"          => "smembers",
        "set_intersect"        => "sinter",
        "set_intersect_store"  => "sinterstore",
        "set_inter_store"      => "sinterstore",
        "set_union"            => "sunion",
        "set_union_store"      => "sunionstore",
        "set_diff"             => "sdiff",
        "set_diff_store"       => "sdiffstore",
        "set_move"             => "smove",
        "set_unless_exists"    => "setnx",
        "rename_unless_exists" => "renamenx",
        "type?"                => "type",
        "zset_add"             => "zadd",
        "zset_count"           => 'zcard',
        "zset_range_by_score"  => 'zrangebyscore',
        "zset_reverse_range"   => 'zrevrange',
        "zset_range"           => 'zrange',
        "zset_delete"          => 'zrem',
        "zset_score"           => 'zscore',
        # these aliases aren't in redis gem
        "background_save"      => 'bgsave',
        "async_save"           => 'bgsave',
        "members"              => 'smembers',
        "decrement_by"         => "decrby",
        "decrement"            => "decr",
        "increment_by"         => "incrby",
        "increment"            => "incr",
        "set_if_nil"           => "setnx",
        "multi_get"            => "mget",
        "random_key"           => "randomkey",
        "random"               => "randomkey",
        "rename_if_nil"        => "renamenx",
        "tail_pop"             => "rpop",
        "pop"                  => "rpop",
        "head_pop"             => "lpop",
        "shift"                => "lpop",
        "list_remove"          => "lrem",
        "index"                => "lindex",
        "trim"                 => "ltrim",
        "list_range"           => "lrange",
        "range"                => "lrange",
        "list_len"             => "llen",
        "len"                  => "llen",
        "head_push"            => "lpush",
        "unshift"              => "lpush",
        "tail_push"            => "rpush",
        "push"                 => "rpush",
        "add"                  => "sadd",
        "set_remove"           => "srem",
        "set_size"             => "scard",
        "member?"              => "sismember",
        "intersect"            => "sinter",
        "intersect_and_store"  => "sinterstore",
        "members"              => "smembers",
        "exists?"              => "exists"
      }

      DISABLED_COMMANDS = {
        "monitor" => true,
        "sync"    => true
      }

      def []=(key,value)
        set(key,value)
      end

      def set(key, value, expiry=nil)
        call_command([:set, key, value]) do |s|
          expire(key, expiry) if s == OK && expiry
          yield s if block_given?
        end
      end

      def sort(key, options={}, &blk)
        cmd = ["SORT"]
        cmd << key
        cmd << "BY #{options[:by]}" if options[:by]
        cmd << "GET #{[options[:get]].flatten * ' GET '}" if options[:get]
        cmd << "#{options[:order]}" if options[:order]
        cmd << "LIMIT #{options[:limit].join(' ')}" if options[:limit]
        call_command(cmd, &blk)
      end

      def incr(key, increment = nil, &blk)
        call_command(increment ? ["incrby",key,increment] : ["incr",key], &blk)
      end

      def decr(key, decrement = nil, &blk)
        call_command(decrement ? ["decrby",key,decrement] : ["decr",key], &blk)
      end

      def select(db, &blk)
        @current_database = db
        call_command(['select', db], &blk)
      end

      def auth(password, &blk)
        @current_password = password
        call_command(['auth', password], &blk)
      end

      # Similar to memcache.rb's #get_multi, returns a hash mapping
      # keys to values.
      def mapped_mget(*keys)
        mget(*keys) do |response|
          result = {}
          response.each do |value|
            key = keys.shift
            result.merge!(key => value) unless value.nil?
          end
          yield result if block_given?
        end
      end

      # Ruby defines a now deprecated type method so we need to override it here
      # since it will never hit method_missing
      def type(key, &blk)
        call_command(['type', key], &blk)
      end

      def quit(&blk)
        call_command(['quit'], &blk)
      end

      def on_error(&blk)
        @err_cb = blk
      end

      def method_missing(*argv, &blk)
        call_command(argv, &blk)
      end

      def call_command(argv, &blk)
        callback { raw_call_command(argv, &blk) }
      end

      def raw_call_command(argv, &blk)
        argv = argv.dup

        if MULTI_BULK_COMMANDS[argv.flatten[0].to_s]
          # TODO improve this code
          argvp   = argv.flatten
          values  = argvp.pop.to_a.flatten
          argvp   = values.unshift(argvp[0])
          command = ["*#{argvp.size}"]
          argvp.each do |v|
            v = v.to_s
            command << "$#{get_size(v)}"
            command << v
          end
          command = command.map {|cmd| "#{cmd}\r\n"}.join
        else
          command = ""
          bulk = nil
          argv[0] = argv[0].to_s.downcase
          argv[0] = ALIASES[argv[0]] if ALIASES[argv[0]]
          raise "#{argv[0]} command is disabled" if DISABLED_COMMANDS[argv[0]]
          if BULK_COMMANDS[argv[0]] and argv.length > 1
            bulk = argv[-1].to_s
            argv[-1] = get_size(bulk)
          end
          command << "#{argv.join(' ')}\r\n"
          command << "#{bulk}\r\n" if bulk
        end

        puts "*** sending: #{command}" if $debug
        @redis_callbacks << [REPLY_PROCESSOR[argv[0]], blk]
        send_data command
      end

      ##
      # errors
      #########################

      class ParserError < StandardError; end
      class ProtocolError < StandardError; end

      class RedisError < StandardError
        attr_accessor :code
      end


      ##
      # em hooks
      #########################

      def self.connect(host = 'localhost', port = 6379 )
        puts "*** connecting" if $debug
        EM.connect host, port, self, host, port
      end

      def initialize(host, port = 6379 )
        puts "*** initializing" if $debug
        @host, @port = host, port
      end

      def connection_completed
        puts "*** connection_complete!" if $debug
        @redis_callbacks = []
        @values = []
        @multibulk_n = 0

        @reconnecting = false
        @connected = true
        succeed
      end

      # 19Feb09 Switched to a custom parser, LineText2 is recursive and can cause
      #         stack overflows when there is too much data.
      # include EM::P::LineText2
      def receive_data(data)
        (@buffer||='') << data
        while index = @buffer.index(DELIM)
          begin
            line = @buffer.slice!(0, index+2)
            process_cmd line
          rescue ParserError
            @buffer[0...0] = line
            break
          end
        end
      end

      def process_cmd(line)
        puts "*** processing #{line}" if $debug
        # first character of buffer will always be the response type
        reply_type = line[0, 1]
        reply_args = line.slice(1..-3) # remove type character and \r\n
        case reply_type

        #e.g. -MISSING
        when MINUS
          @redis_callbacks.shift # throw away the cb?
          if @err_cb
            @err_cb.call(reply_args)
          else
            err = RedisError.new
            err.code = reply_args
            raise err, "Redis server returned error code: #{err.code}"
          end

        # e.g. +OK
        when PLUS
          dispatch_response(reply_args)

        # e.g. $3\r\nabc\r\n
        # 'bulk' is more complex because it could be part of multi-bulk
        when DOLLAR
          data_len = Integer(reply_args)
          if data_len == -1 # expect no data; return nil
            if @multibulk_n > 0 # we're in the middle of a multibulk reply
              @values << nil
              if @values.size == @multibulk_n # DING, we're done
                dispatch_response(@values)
                @values = []
                @multibulk_n = 0
              end
            else
              dispatch_response(nil)
            end
          elsif @buffer.size >= data_len + 2 # buffer is full of expected data
            if @multibulk_n > 0 # we're in the middle of a multibulk reply
              @values << @buffer.slice!(0, data_len)
              if @values.size == @multibulk_n # DING, we're done
                dispatch_response(@values)
                @values = []
                @multibulk_n = 0
              end
            else # not multibulk
              value = @buffer.slice!(0, data_len)
              dispatch_response(value)
            end
            @buffer.slice!(0,2) # tossing \r\n
          else # buffer isn't full or nil
            # FYI, ParseError puts command back on head of buffer, waits for
            # more data complete buffer
            raise ParserError 
          end

        #e.g. :8
        when COLON
          dispatch_response(Integer(reply_args))

        #e.g. *2\r\n$1\r\na\r\n$1\r\nb\r\n 
        when ASTERISK
          @multibulk_n = Integer(reply_args)
          dispatch_response(nil) if @multibulk_n == -1

        # Whu?
        else
          raise ProtocolError, "reply type not recognized: #{line.strip}"
        end
      end

      def dispatch_response(value)
        processor, blk = @redis_callbacks.shift
        value = processor.call(value) if processor
        blk.call(value) if blk
      end

      def unbind
        puts "*** unbinding" if $debug
        if @connected or @reconnecting
          EM.add_timer(1) do
            reconnect @host, @port
            auth @current_password if @current_password
            select @current_database if @current_database
          end
          @connected = false
          @reconnecting = true
          @deferred_status = nil
        else
          raise 'Unable to connect to redis server'
        end
      end

      private
        def get_size(string)
          string.respond_to?(:bytesize) ? string.bytesize : string.size
        end

    end
  end
end
