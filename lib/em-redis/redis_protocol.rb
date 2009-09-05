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

      def del(key, &blk) #delete
        inline_command "DEL", key, &blk
      end
      alias_method :delete, :del

      def exists(key, &blk) #exists?
        inline_command "EXISTS", key, &blk
      end
      alias_method :exists?, :exists

      def decrby(key, value, &blk) #decrement_by
        inline_command "DECRBY", key, value, &blk
      end
      alias_method :decrement_by, :decrby

      def decr(key, &blk) #decrement
        inline_command "DECR", key, &blk
      end
      alias_method :decrement, :decr

      def incrby(key, value, &blk)
        inline_command "INCRBY", key, value, &blk
      end
      alias_method :increment_by, :incrby

      def incr(key, &blk) #increment
        inline_command "INCR", key, &blk
      end
      alias_method :increment, :incr

      def setnx(key, value, &blk) #set_if_nil
        multiline_command "SETNX", key, value, &blk
      end
      alias_method :set_if_nil, :setnx

      def mget(*keys, &blk) #multi_get
        inline_command "MGET", *keys, &blk
      end
      alias_method :multi_get, :mget

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

      def randomkey(&blk) #random_key, random
        inline_command "RANDOMKEY", &blk
      end
      alias_method :random_key, :randomkey
      alias_method :random, :randomkey

      def rename(old_name, new_name, &blk)
        inline_command "RENAME", old_name, new_name, &blk
      end

      def renamenx(old_name, new_name, &blk) #rename_if_nil
        inline_command "RENAMENX", old_name, new_name, &blk
      end
      alias_method :rename_if_nil, :renamenx

      def dbsize(&blk)
        inline_command "DBSIZE", &blk
      end

      def expire(key, &blk)
        inline_command "EXPIRE", key, &blk
      end
      
      #RPUSH,LPUSH,LLEN,LRANGE,LTRIM,LINDEX,LSET,LREM,LPOP,RPOP
      def rpop(key, &blk) # tail_pop, pop
        inline_command "RPOP", key, &blk
      end
      alias_method :tail_pop, :rpop
      alias_method :pop, :rpop

      def lpop(key, &blk) #head_pop, shift
        inline_command "LPOP", key, &blk
      end
      alias_method :head_pop, :lpop
      alias_method :shift, :lpop


      def lrem(key, value, count=0, &blk) #list_remove
        multiline_command "LREM", key, count, value, &blk
      end
      alias_method :list_remove, :lrem

      def lset(key, index, value, &blk) #list_set
        multiline_command "LSET", key, index, value, &blk
      end
      alias_method :list_set, :lset

      def lindex(key, index, &blk) #list_index, index
        inline_command "LINDEX", key, index, &blk
      end
      alias_method :list_index, :lindex
      alias_method :index, :lindex

      def ltrim(key, start, ending, &blk) # list_trim, trim
        inline_command "LTRIM", key, start, ending, &blk
      end
      alias_method :list_trim, :ltrim
      alias_method :trim, :ltrim

      def lrange(key, start, range, &blk) #list_range, range
        inline_command "LRANGE", key, start, range, &blk
      end
      alias_method :list_range, :lrange
      alias_method :range, :lrange

      def llen(key, &blk) #list_len, len
        inline_command "LLEN", key, &blk
      end
      alias_method :list_len, :llen 
      alias_method :len, :llen 

      def lpush(key, value, &blk) #head_push, unshift
        multiline_command "LPUSH", key, value, &blk
      end
      alias_method :head_push, :lpush
      alias_method :unshift, :lpush

      def rpush(key, value, &blk) #tail_push, push
        multiline_command "RPUSH", key, value, &blk
      end
      alias_method :tail_push, :rpush
      alias_method :push, :rpush

      
      #SADD,SREM,SCARD,SISMEMBER,SINTER,SINTERSTORE,SUNION,SUNIONSTORE,SMEMBERS
      def sadd(key, value, &blk) #set_add, add
        multiline_command "SADD", key, value, &blk
      end
      alias_method :set_add, :sadd 
      alias_method :add, :sadd 

      def srem(key, value, &blk) #set_remove
        multiline_command "SREM", key, value, &blk
      end
      alias_method :set_remove, :srem

      def scard(key, &blk) # set_size
        inline_command "SCARD", key, &blk
      end
      alias_method :set_size, :scard

      def sismember(key, value, &blk) #set_member? member?
        multiline_command "SISMEMBER", key, value, &blk
      end
      alias_method :set_member?, :sismember
      alias_method :member?, :sismember

      def sinter(*keys, &blk) #intersect
        inline_command "SINTER", *keys, &blk
      end
      alias_method :intersect, :sinter

      def sinterstore(target_key, *keys, &blk) #intersect_and_store
        inline_command "SINTERSTORE", target_key, *keys, &blk
      end
      alias_method :intersect_and_store, :sinterstore

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

      def smembers(key, &blk) #set_members, members
        inline_command "SMEMBERS", key, &blk
      end
      alias_method :set_members, :smembers
      alias_method :members, :smembers

      
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

      def bgsave(&blk) #background_save, async_save
        inline_command "BGSAVE", &blk
      end
      alias_method :background_save, :bgsave
      alias_method :async_save, :bgsave

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
      
      # MONITOR's a bit tricky
      def monitor
      end

      def on_error(&blk)
        @err_cb = blk
      end


      ## 
      # Generic request methods      
      #########################

      def inline_command(*args, &blk)
        callback {
          command = args.shift
          blk ||= lambda { } # all cmds must at least have a no-op callback
          @redis_callbacks << blk 
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
          @redis_callbacks << blk 
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
      class ProtocolError < StandardError; end

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
        # first character of buffer will always be the response type
        reply_type = line[0].chr 
        reply_args = line.slice(1..-3) # remove type character and \r\n
        case reply_type

        # e.g. +OK
        when C_SINGLE 
          if cb = @redis_callbacks.shift
            cb.call( reply_args )
          end

        # e.g. $3\r\nabc\r\n
        # 'bulk' is more complex because it could be part of multi-bulk
        when C_BULK 
          data_len = Integer( reply_args ) 
          if data_len == -1 # expect no data; return nil
            if @multibulk_n > 0 # we're in the middle of a multibulk reply
              @values << nil
              if @values.size == @multibulk_n # DING, we're done
                if cb = @redis_callbacks.shift
                  cb.call(@values)
                  @values = []
                  @multibulk_n = 0
                end
              end
            else 
              if cb = @redis_callbacks.shift
                cb.call(nil)
              end
            end
          elsif @buffer.size >= data_len + 2 # buffer is full of expected data
            if @multibulk_n > 0 # we're in the middle of a multibulk reply
              @values << @buffer.slice!(0,data_len) 
              if @values.size == @multibulk_n # DING, we're done
                if cb = @redis_callbacks.shift
                  cb.call(@values)
                  @values = []
                  @multibulk_n = 0
                end
              end
            else # not multibulk
              value = @buffer.slice!(0,data_len)
              if cb = @redis_callbacks.shift
                cb.call(value)
              end
            end
            @buffer.slice!(0,2) # tossing \r\n
          else # buffer isn't full or nil
            # FYI, ParseError puts command back on head of buffer, waits for
            # more data complete buffer
            raise ParserError 
          end
        #e.g. :8
        when C_INT
          if cb = @redis_callbacks.shift
            cb.call( Integer(reply_args) )
          end
        #e.g. *2\r\n$1\r\na\r\n$1\r\nb\r\n 
        when C_MULTI
          @multibulk_n = Integer(reply_args)
          if @multibulk_n == -1
            if cb = @redis_callbacks.shift
              cb.call(nil)
            end
          end
        #e.g. -MISSING
        when C_ERR
          @redis_callbacks.shift # throw away the cb?
          if @err_cb
            @err_cb.call(reply_args)
          else
            err = RedisError.new
            err.code = reply_args
            raise err, "Redis server returned error code: #{err.code}"
          end
        # Whu?
        else
          raise ProtocolError, "reply type not recognized: #{line.strip}"
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
