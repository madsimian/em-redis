require File.expand_path(File.dirname(__FILE__) + "/test_helper.rb")

EM.describe EM::Protocols::Redis, "connected to an empty db" do

  before do
    @c = EM::Protocols::Redis.connect :db => 14
    @c.flushdb
  end

  should "be able to set a string value" do
    @c.set("foo", "bar") do |r|
      r.should == "OK"
      done
    end
  end

  should "be able to increment the value of a string" do
    @c.incr "foo" do |r|
      r.should == 1
      @c.incr "foo" do |r|
        r.should == 2
        done
      end
    end
  end

  should "be able to increment the value of a string by an amount" do
    @c.incrby "foo", 10 do |r|
      r.should == 10
      done
    end
  end

  should "be able to decrement the value of a string" do
    @c.incr "foo" do |r|
      r.should == 1
      @c.decr "foo" do |r|
        r.should == 0
        done
      end
    end
  end

  should "be able to decrement the value of a string by an amount" do
    @c.incrby "foo", 20 do |r|
      r.should == 20
      @c.decrby "foo", 10 do |r|
        r.should == 10
        done
      end
    end
  end

  should "be able to 'lpush' to a nonexistent list" do
    @c.lpush("foo", "bar") do |r|
      r.should == 1
      done
    end
  end

  should "be able to 'rpush' to a nonexistent list" do
    @c.rpush("foo", "bar") do |r|
      r.should == 1
      done
    end
  end


  should "be able to get the size of the database" do
    @c.dbsize do |r|
      r.should == 0
      done
    end
  end

  should "be able to add a member to a nonexistent set" do
    @c.sadd("set_foo", "bar") do |r|
      r.should == true
      done
    end
  end

  should "be able to get info about the db as a hash" do
    @c.info do |r|
      r.should.key? :redis_version
      done
    end
  end

  should "be able to save db" do
    @c.save do |r|
      r.should == "OK"
      done
    end
  end

  should "be able to save db in the background" do
    @c.bgsave do |r|
      r.should == "Background saving started"
      done
    end
  end

end

EM.describe EM::Protocols::Redis, "connected to a db containing some simple string-valued keys" do

  before do
    @c = EM::Protocols::Redis.connect :db => 14
    @c.flushdb
    @c.set "a", "b"
    @c.set "x", "y"
  end

  should "be able to fetch the values of multiple keys" do
    @c.mget "a", "x" do |r|
      r.should == ["b", "y"]
      done
    end
  end

  should "be able to fetch the values of multiple keys in a hash" do
    @c.mapped_mget "a", "x" do |r|
      r.should == {"a" => "b",  "x" => "y"}
      done
    end
  end

  should "be able to fetch all the keys" do
    @c.keys "*" do |r|
      r.sort.should == ["a", "x"]
      done
    end
  end

  should "be able to set a value if a key doesn't exist" do
    @c.setnx "a", "foo" do |r|
      r.should == false
      @c.setnx "zzz", "foo" do |r|
        r.should == true
        done
      end
    end
  end

  should "be able to test for the existence of a key" do
    @c.exists "a" do |r|
      r.should == true
      @c.exists "zzz" do |r|
        r.should == false
        done
      end
    end
  end

  should "be able to delete a key" do
    @c.del "a" do |r|
      r.should == true
      @c.exists "a" do |r|
        r.should == false
        @c.del "a" do |r|
          r.should == false
          done
        end
      end
    end
  end

  should "be able to detect the type of a key, existing or not" do
    @c.type "a" do |r|
      r.should == "string"
      @c.type "zzz" do |r|
        r.should == "none"
        done
      end
    end
  end

  should "be able to rename a key" do
    @c.rename "a", "x" do |r|
      @c.get "x" do |r|
        r.should == "b"
        done
      end
    end
  end

  should "be able to rename a key unless it exists" do
    @c.renamenx "a", "x" do |r|
      r.should == false
      @c.renamenx "a", "zzz" do |r|
        r.should == true
        @c.get "zzz" do |r|
          r.should == "b"
          done
        end
      end
    end
  end


end

EM.describe EM::Protocols::Redis, "connected to a db containing a list" do

  before do
    @c = EM::Protocols::Redis.connect :db => 14
    @c.flushdb
    @c.lpush "foo", "c"
    @c.lpush "foo", "b"
    @c.lpush "foo", "a"
  end

  should "be able to 'lset' a list member and 'lindex' to retrieve it" do
    @c.lset("foo",  1, "bar") do |r|
      @c.lindex("foo", 1) do |r|
        r.should == "bar"
        done
      end
    end
  end

  should "be able to 'rpush' onto the tail of the list" do
    @c.rpush "foo", "d" do |r|
      r.should == 4
      @c.rpop "foo" do |r|
        r.should == "d"
        done
      end
    end
  end

  should "be able to 'lpush' onto the head of the list" do
    @c.lpush "foo", "d" do |r|
      r.should == 4
      @c.lpop "foo" do |r|
        r.should == "d"
        done
      end
    end
  end

  should "be able to 'rpop' off the tail of the list" do
    @c.rpop("foo") do |r|
      r.should == "c"
      done
    end
  end

  should "be able to 'lpop' off the tail of the list" do
    @c.lpop("foo") do |r|
      r.should == "a"
      done
    end
  end

  should "be able to get a range of values from a list" do
    @c.lrange("foo", 0, 1) do |r|
      r.should == ["a", "b"]
      done
    end
  end

  should "be able to 'ltrim' a list" do
    @c.ltrim("foo", 0, 1) do |r|
      r.should == "OK"
      @c.llen("foo") do |r|
        r.should == 2
        done
      end
    end
  end

  should "be able to 'rem' a list element" do
    @c.lrem("foo", 0, "a") do |r|
      r.should == 1
      @c.llen("foo") do |r|
        r.should == 2
        done
      end
    end
  end

  should "be able to detect the type of a list" do
    @c.type "foo" do |r|
      r.should == "list"
      done
    end
  end

end

EM.describe EM::Protocols::Redis, "connected to a db containing two sets" do
  before do
    @c = EM::Protocols::Redis.connect :db => 14
    @c.flushdb
    @c.sadd "foo", "a"
    @c.sadd "foo", "b"
    @c.sadd "foo", "c"
    @c.sadd "bar", "c"
    @c.sadd "bar", "d"
    @c.sadd "bar", "e"
  end

  should "be able to find a set's cardinality" do
    @c.scard("foo") do |r|
      r.should == 3
      done
    end
  end

  should "be able to add a new member to a set unless it is a duplicate" do
    @c.sadd("foo", "d") do |r|
      r.should == true # success
      @c.sadd("foo", "a") do |r|
        r.should == false # failure
        @c.scard("foo") do |r|
          r.should == 4
          done
        end
      end
    end
  end

  should "be able to remove a set member if it exists" do
    @c.srem("foo", "a") do |r|
      r.should == true
      @c.srem("foo", "z") do |r|
        r.should == false
        @c.scard("foo") do |r|
          r.should == 2
          done
        end
      end
    end
  end

  should "be able to retrieve a set's members" do
    @c.smembers("foo") do |r|
      r.sort.should == ["a", "b", "c"]
      done
    end
  end

  should "be able to detect set membership" do
    @c.sismember("foo", "a") do |r|
      r.should == true
      @c.sismember("foo", "z") do |r|
        r.should == false
        done
      end
    end
  end

  should "be able to find the sets' intersection" do
    @c.sinter("foo", "bar") do |r|
      r.should == ["c"]
      done
    end
  end

  should "be able to find and store the sets' intersection" do
    @c.sinterstore("baz", "foo", "bar") do |r|
      r.should == 1
      @c.smembers("baz") do |r|
        r.should == ["c"]
        done
      end
    end
  end

  should "be able to find the sets' union" do
    @c.sunion("foo", "bar") do |r|
      r.sort.should == ["a","b","c","d","e"]
      done
    end
  end

  should "be able to find and store the sets' union" do
    @c.sunionstore("baz", "foo", "bar") do |r|
      r.should == 5
      @c.smembers("baz") do |r|
        r.sort.should == ["a","b","c","d","e"]
        done
      end
    end
  end

  should "be able to detect the type of a set" do
    @c.type "foo" do |r|
      r.should == "set"
      done
    end
  end

end


EM.describe EM::Protocols::Redis, "connected to a db containing three linked lists" do
  before do
    @c = EM::Protocols::Redis.connect :db => 14
    @c.flushdb
    @c.rpush "foo", "a"
    @c.rpush "foo", "b"
    @c.set "a_sort", "2"
    @c.set "b_sort", "1"
    @c.set "a_data", "foo"
    @c.set "b_data", "bar"
  end

  should "be able to collate a sorted set of data" do
    @c.sort("foo", :by => "*_sort", :get => "*_data") do |r|
      r.sort.should == ["bar", "foo"]
      done
    end
  end

  should "be able to get keys selectively" do
    @c.keys "a_*" do |r|
      r.sort.should == ["a_data", "a_sort"]
      done
    end
  end
end

EM.describe EM::Protocols::Redis, "connected to a db containing some hash-valued keys" do

  before do
    @c = EM::Protocols::Redis.connect :db => 14
    @c.flushdb
    @c.hset "a", "one", "foo"
    @c.hset "a", "two", true
    @c.hset "a", "three", 1
  end

  should "be able to fetch a field in the hash stored at key" do
    @c.hget("a", "one") { |r| r.should == "foo" }
    @c.hget("a", "two") { |r| r.should == "true" }
    @c.hget("a", "three") { |r| r.should == "1"; done }
  end

  should "be able to fetch a nonexistent field in the hash stored at key" do
    @c.hget "a", "four" do |r|
      r.should == nil
      done
    end
  end

  should "be able to check if a field exists in the hash stored at key" do
    @c.hexists("a", "one") { |r| r.should == true }
    @c.hexists("a", "four") { |r| r.should == false; done }
  end

  should "be able to delete a field in the hash stored at key" do
    @c.hdel("a", "one") do |r|
      r.should == true
      @c.hget "a", "one" do |r|
        r.should == nil
        done
      end
    end
  end

  should "be able to fetch an entire hash stored at key" do
    @c.hgetall "a" do |r|
      r.should == {"one" => "foo", "two" => "true", "three" => "1"}
      done
    end
  end

  should "be able to increment a field in the hash stored at key" do
    @c.hincrby "a", "three", 1 do |r|
      r.should == 2
      done
    end
  end

  should "be able to fetch field names in the hash stored at key" do
    @c.hkeys "a" do |r|
      r.should == ["one", "two", "three"]
      done
    end
  end

  should "be able to fetch field values in the hash stored at key" do
    @c.hvals "a" do |r|
      r.should == ["foo", "true", "1"]
      done
    end
  end

  should "be able to fetch multiple fields in the hash stored at key" do
    @c.hmget "a", "one", "two", "three", "four" do |r|
      r.should == ["foo", "true", "1", nil]
      done
    end
  end

  should "be able to set multiple fields in the hash stored at key" do
    @c.hmset "a", "four", "foo", "five", "bar" do |r|
      r.should == "OK"
      @c.hget("a", "four") { |r| r.should == "foo" }
      @c.hget("a", "five") { |r| r.should == "bar"; done }
    end
  end

  should "be able to set a field if not already set in the hash stored at key" do
    @c.hsetnx "a", "four", "foo" do |r|
      r.should == true
      @c.hsetnx "a", "four", "bar" do |r|
        r.should == false
        done
      end
    end
  end

end

EM.describe EM::Protocols::Redis, "when reconnecting" do
  before do
    @c = EM::Protocols::Redis.connect :db => 14
    @c.flushdb
  end

  should "select previously selected datase" do
    #simulate disconnect
    @c.set('foo', 'a') { @c.close_connection_after_writing }

    EM.add_timer(2) do
      @c.get('foo') do |r|
        r.should == 'a'
        @c.get('non_existing') do |r|
          r.should == nil
          done
        end
      end
    end
  end
end
