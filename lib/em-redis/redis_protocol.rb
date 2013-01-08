require 'rubygems'
require 'eventmachine'
require 'uri'

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

      BOOLEAN_PROCESSOR = lambda{|r| %w(1 OK).include? r.to_s}

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
        "select"    => BOOLEAN_PROCESSOR,
        "hexists"   => BOOLEAN_PROCESSOR,
        "hset"      => BOOLEAN_PROCESSOR,
        "hdel"      => BOOLEAN_PROCESSOR,
        "hsetnx"    => BOOLEAN_PROCESSOR,
        "hgetall"   => lambda{|r| Hash[*r]},
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
        "zset_count"           => "zcard",
        "zset_range_by_score"  => "zrangebyscore",
        "zset_reverse_range"   => "zrevrange",
        "zset_range"           => "zrange",
        "zset_delete"          => "zrem",
        "zset_score"           => "zscore",
        "zset_incr_by"         => "zincrby",
        "zset_increment_by"    => "zincrby",
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
        call_command(["set", key, value]) do |s|
          yield s if block_given?
        end
        expire(key, expiry) if expiry
      end

      def sort(key, options={}, &blk)
        cmd = ["sort", key]
        cmd << ["by", options[:by]] if options[:by]
        Array(options[:get]).each do |v|
          cmd << ["get", v]
        end
        cmd << options[:order].split(" ") if options[:order]
        cmd << ["limit", options[:limit]] if options[:limit]
        cmd << ["store", options[:store]] if options[:store]
        call_command(cmd.flatten, &blk)
      end

      def incr(key, increment = nil, &blk)
        call_command(increment ? ["incrby",key,increment] : ["incr",key], &blk)
      end

      def decr(key, decrement = nil, &blk)
        call_command(decrement ? ["decrby",key,decrement] : ["decr",key], &blk)
      end

      def select(db, &blk)
        @db = db.to_i
        call_command(['select', @db], &blk)
      end

      def auth(password, &blk)
        @password = password
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

      def errback(&blk)
        @error_callback = blk
      end
      alias_method :on_error, :errback

      def error(klass, msg)
        err = klass.new(msg)
        err.code = msg if err.respond_to?(:code)
        @error_callback.call(err)
      end

      def before_reconnect(&blk)
        @reconnect_callbacks[:before] = blk
      end

      def after_reconnect(&blk)
        @reconnect_callbacks[:after] = blk
      end

      def method_missing(*argv, &blk)
        call_command(argv, &blk)
      end

      def call_command(argv, &blk)
        callback { raw_call_command(argv, &blk) }
      end

      def raw_call_command(argv, &blk)
        argv[0] = argv[0].to_s unless argv[0].kind_of? String
        argv[0] = argv[0].downcase
        send_command(argv)
        @redis_callbacks << [REPLY_PROCESSOR[argv[0]], blk]
      end

      def call_commands(argvs, &blk)
        callback { raw_call_commands(argvs, &blk) }
      end

      def raw_call_commands(argvs, &blk)
        if argvs.empty?  # Shortcut
          blk.call []
          return
        end

        argvs.each do |argv|
          argv[0] = argv[0].to_s unless argv[0].kind_of? String
          send_command argv
        end
        # FIXME: argvs may contain heterogenous commands, storing all
        # REPLY_PROCESSORs may turn out expensive and has been omitted
        # for now.
        @redis_callbacks << [nil, argvs.length, blk]
      end

      def send_command(argv)
        argv = argv.dup

        error DisabledCommand, "#{argv[0]} command is disabled" if DISABLED_COMMANDS[argv[0]]
        argv[0] = ALIASES[argv[0]] if ALIASES[argv[0]]

        if argv[-1].is_a?(Hash)
          argv[-1] = argv[-1].to_a
          argv.flatten!
        end

        command = ["*#{argv.size}"]
        argv.each do |v|
          v = v.to_s
          command << "$#{get_size(v)}"
          command << v
        end
        command = command.map {|cmd| cmd + DELIM}.join

        @logger.debug { "*** sending: #{command}" } if @logger
        send_data command
      end

      ##
      # errors
      #########################

      class DisabledCommand < StandardError; end
      class ParserError < StandardError; end
      class ProtocolError < StandardError; end
      class ConnectionError < StandardError; end

      class RedisError < StandardError
        attr_accessor :code

        def initialize(*args)
          args[0] = "Redis server returned error code: #{args[0]}"
          super
        end
      end

      ##
      # em hooks
      #########################

      class << self
        def parse_url(url)
          begin
            uri = URI.parse(url)
            {
              :host => uri.host,
              :port => uri.port,
              :password => uri.password
            }
          rescue
            error ArgumentError, 'invalid redis url'
          end
        end

        def connect(*args)
          case args.length
          when 0
            options = {}
          when 1
            arg = args.shift
            case arg
            when Hash then options = arg
            when String then options = parse_url(arg)
            else error ArgumentError, 'first argument must be Hash or String'
            end
          when 2
            options = {:host => args[1], :port => args[2]}
          else
            error ArgumentError, "wrong number of arguments (#{args.length} for 1)"
          end
          options[:host] ||= '127.0.0.1'
          options[:port]   = (options[:port] || 6379).to_i
          EM.connect options[:host], options[:port], self, options
        end
      end

      def initialize(options = {})
        @host           = options[:host]
        @port           = options[:port]
        @db             = (options[:db] || 0).to_i
        @password       = options[:password]
        @auto_reconnect = options[:auto_reconnect] || true
        @logger         = options[:logger]
        @error_callback = lambda do |err|
          raise err
        end
        @reconnect_callbacks = {
          :before => lambda{},
          :after  => lambda{}
        }
        @values = []

        # These commands should be first
        auth_and_select_db
      end

      def auth_and_select_db
        call_command(["auth", @password]) if @password
        call_command(["select", @db]) unless @db == 0
      end
      private :auth_and_select_db

      def connection_completed
        @logger.debug { "Connected to #{@host}:#{@port}" } if @logger

        @reconnect_callbacks[:after].call if @reconnecting

        @redis_callbacks = []
        @multibulk_n     = false
        @reconnecting    = false
        @connected       = true

        succeed
      end

      # 19Feb09 Switched to a custom parser, LineText2 is recursive and can cause
      #         stack overflows when there is too much data.
      # include EM::P::LineText2
      def receive_data(data)
        (@buffer ||= '') << data
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
        @logger.debug { "*** processing #{line}" } if @logger
        # first character of buffer will always be the response type
        reply_type = line[0, 1]
        reply_args = line.slice(1..-3) # remove type character and \r\n
        case reply_type
        # e.g. -ERR
        when MINUS
          # server ERROR
          dispatch_error(reply_args)
        # e.g. +OK
        when PLUS
          dispatch_response(reply_args)
        # e.g. $3\r\nabc\r\n
        # 'bulk' is more complex because it could be part of multi-bulk
        when DOLLAR
          data_len = Integer(reply_args)
          if data_len == -1 # expect no data; return nil
            dispatch_response(nil)
          elsif @buffer.size >= data_len + 2 # buffer is full of expected data
            dispatch_response(@buffer.slice!(0, data_len))
            @buffer.slice!(0,2) # tossing \r\n
          else # buffer isn't full or nil
            raise ParserError
          end
        # e.g. :8
        when COLON
          dispatch_response(Integer(reply_args))
        # e.g. *2\r\n$1\r\na\r\n$1\r\nb\r\n
        when ASTERISK
          multibulk_count = Integer(reply_args)
          if multibulk_count == -1 || multibulk_count == 0
            dispatch_response([])
          else
            start_multibulk(multibulk_count)
          end
        # WAT?
        else
          error ProtocolError, "reply type not recognized: #{line.strip}"
        end
      end

      def dispatch_error(code)
        @redis_callbacks.shift
        error RedisError, code
      end

      def dispatch_response(value)
        if @multibulk_n
          @multibulk_values << value
          @multibulk_n -= 1

          if @multibulk_n == 0
            value = @multibulk_values
            @multibulk_n = false
          else
            return
          end
        end

        callback = @redis_callbacks.shift
        if callback.kind_of?(Array) && callback.length == 2
          processor, blk = callback
          value = processor.call(value) if processor
          blk.call(value) if blk
        elsif callback.kind_of?(Array) && callback.length == 3
          processor, pipeline_count, blk = callback
          value = processor.call(value) if processor
          @values << value
          if pipeline_count > 1
            @redis_callbacks.unshift [processor, pipeline_count - 1, blk]
          else
            blk.call(@values) if blk
            @values = []
          end
        end
      end

      def start_multibulk(multibulk_count)
        @multibulk_n = multibulk_count
        @multibulk_values = []
      end

      def connected?
        @connected || false
      end

      def close
        @closing = true
        close_after_writing
      end

      def unbind
        @logger.debug { "Disconnected" } if @logger
        if @closing
          @reconnecting = false
        elsif (@connected || @reconnecting) && @auto_reconnect
          @reconnect_callbacks[:before].call if @connected
          @reconnecting = true
          EM.add_timer(1) do
            @logger.debug { "Reconnecting to #{@host}:#{@port}" } if @logger
            reconnect @host, @port
            auth_and_select_db
          end
        elsif @connected
          error ConnectionError, 'connection closed'
        else
          error ConnectionError, 'unable to connect to redis server'
        end
        @connected = false
        @deferred_status = nil
      end

      private
        def get_size(string)
          string.respond_to?(:bytesize) ? string.bytesize : string.size
        end

    end
  end
end
