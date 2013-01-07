require File.expand_path(File.dirname(__FILE__) + "/test_helper.rb")
require 'logger'

EM.describe EM::Protocols::Redis do
  default_timeout 1

  before do
    @r = EM::Protocols::Redis.connect :db => 14
    @r.flushdb
    @r['foo'] = 'bar'
  end


  should "be able to provide a logger" do
    log = StringIO.new
    r = EM::Protocols::Redis.connect :db => 14, :logger => Logger.new(log)
    r.ping do
      log.string.should.include "ping"
      done
    end
  end

  it "should be able to PING" do
    @r.ping { |r| r.should == 'PONG'; done }
  end

  it "should be able to GET a key" do
    @r.get('foo') { |r| r.should == 'bar'; done }
  end

  it "should be able to SET a key" do
    @r['foo'] = 'nik'
    @r.get('foo') { |r| r.should == 'nik'; done }
  end

  it "should properly handle trailing newline characters" do
    @r['foo'] = "bar\n"
    @r.get('foo') { |r| r.should == "bar\n"; done }
  end

  it "should store and retrieve all possible characters at the beginning and the end of a string" do
    (0..255).each do |char_idx|
      string = "#{char_idx.chr}---#{char_idx.chr}"
      @r['foo'] = string
      @r.get('foo') { |r| r.should == string }
    end
    @r.ping { done }
  end

  it "should be able to SET a key with an expiry" do
    timeout(3)

    @r.set('foo', 'bar', 1)
    @r.get('foo') { |r| r.should == 'bar' }
    EM.add_timer(2) do
      @r.get('foo') { |r| r.should == nil }
      @r.ping { done }
    end
  end

  it "should be able to return a TTL for a key" do
    @r.set('foo', 'bar', 1)
    @r.ttl('foo') { |r| r.should == 1; done }
  end

  it "should be able to SETNX" do
    @r['foo'] = 'nik'
    @r.get('foo') { |r| r.should == 'nik' }
    @r.setnx 'foo', 'bar'
    @r.get('foo') { |r| r.should == 'nik' }

    @r.ping { done }
  end
  #
  it "should be able to GETSET" do
   @r.getset('foo', 'baz') { |r| r.should == 'bar' }
   @r.get('foo') { |r| r.should == 'baz'; done }
  end
  #
  it "should be able to INCR a key" do
    @r.del('counter')
    @r.incr('counter') { |r| r.should == 1 }
    @r.incr('counter') { |r| r.should == 2 }
    @r.incr('counter') { |r| r.should == 3 }

    @r.ping { done }
  end
  #
  it "should be able to INCRBY a key" do
    @r.del('counter')
    @r.incrby('counter', 1) { |r| r.should == 1 }
    @r.incrby('counter', 2) { |r| r.should == 3 }
    @r.incrby('counter', 3) { |r| r.should == 6 }

    @r.ping { done }
  end
  #
  it "should be able to DECR a key" do
    @r.del('counter')
    @r.incr('counter') { |r| r.should == 1 }
    @r.incr('counter') { |r| r.should == 2 }
    @r.incr('counter') { |r| r.should == 3 }
    @r.decr('counter') { |r| r.should == 2 }
    @r.decr('counter', 2) { |r| r.should == 0; done }
  end
  #
  it "should be able to RANDKEY" do
    @r.randkey { |r| r.should.not == nil; done }
  end
  #
  it "should be able to RENAME a key" do
    @r.del 'foo'
    @r.del 'bar'
    @r['foo'] = 'hi'
    @r.rename 'foo', 'bar'
    @r.get('bar') { |r| r.should == 'hi' ; done }
  end
  #
  it "should be able to RENAMENX a key" do
    @r.del 'foo'
    @r.del 'bar'
    @r['foo'] = 'hi'
    @r['bar'] = 'ohai'
    @r.renamenx 'foo', 'bar'
    @r.get('bar') { |r| r.should == 'ohai' ; done }
  end
  #
  it "should be able to get DBSIZE of the database" do
    dbsize_without_foo, dbsize_with_foo = nil
    @r.delete 'foo'
    @r.dbsize { |r| dbsize_without_foo = r }
    @r['foo'] = 0
    @r.dbsize { |r| dbsize_with_foo = r }

    @r.ping do
      dbsize_with_foo.should == dbsize_without_foo + 1
      done
    end
  end
  #
  it "should be able to EXPIRE a key" do
    timeout(3)

    @r['foo'] = 'bar'
    @r.expire 'foo', 1
    @r.get('foo') { |r| r.should == "bar" }
    EM.add_timer(2) do
      @r.get('foo') { |r| r.should == nil }
      @r.ping { done }
    end
  end
  #
  it "should be able to EXISTS" do
    @r['foo'] = 'nik'
    @r.exists('foo') { |r| r.should == true }
    @r.del 'foo'
    @r.exists('foo') { |r| r.should == false ; done }
  end
  #
  it "should be able to KEYS" do
    @r.keys("f*") { |keys| keys.each { |key| @r.del key } }
    @r['f'] = 'nik'
    @r['fo'] = 'nak'
    @r['foo'] = 'qux'
    @r.keys("f*") { |r| r.sort.should == ['f', 'fo', 'foo'].sort }

    @r.ping { done }
  end
  #
  it "should be able to return a random key (RANDOMKEY)" do
    3.times do |i|
      @r.randomkey do |r|
        @r.exists(r) do |e|
          e.should == true
          done if i == 2
        end
      end
    end
  end
  #
  it "should be able to check the TYPE of a key" do
    @r['foo'] = 'nik'
    @r.type('foo') { |r| r.should == "string" }
    @r.del 'foo'
    @r.type('foo') { |r| r.should == "none" ; done }
  end
  #
  it "should be able to push to the head of a list (LPUSH)" do
    @r.lpush "list", 'hello'
    @r.lpush "list", 42
    @r.type('list') { |r| r.should == "list" }
    @r.llen('list') { |r| r.should == 2 }
    @r.lpop('list') { |r| r.should == '42'; done }
  end
  #
  it "should be able to push to the tail of a list (RPUSH)" do
    @r.rpush "list", 'hello'
    @r.type('list') { |r| r.should == "list" }
    @r.llen('list') { |r| r.should == 1 ; done }
  end
  #
  it "should be able to pop the tail of a list (RPOP)" do
    @r.rpush "list", 'hello'
    @r.rpush"list", 'goodbye'
    @r.type('list') { |r| r.should == "list" }
    @r.llen('list') { |r| r.should == 2 }
    @r.rpop('list') { |r| r.should == 'goodbye'; done }
  end
  #
  it "should be able to pop the head of a list (LPOP)" do
    @r.rpush "list", 'hello'
    @r.rpush "list", 'goodbye'
    @r.type('list') { |r| r.should == "list" }
    @r.llen('list') { |r| r.should == 2 }
    @r.lpop('list') { |r| r.should == 'hello'; done }
  end
  #
  it "should be able to get the length of a list (LLEN)" do
    @r.rpush "list", 'hello'
    @r.rpush "list", 'goodbye'
    @r.type('list') { |r| r.should == "list" }
    @r.llen('list') { |r| r.should == 2 ; done }
  end
  #
  it "should be able to get a range of values from a list (LRANGE)" do
    @r.rpush "list", 'hello'
    @r.rpush "list", 'goodbye'
    @r.rpush "list", '1'
    @r.rpush "list", '2'
    @r.rpush "list", '3'
    @r.type('list') { |r| r.should == "list" }
    @r.llen('list') { |r| r.should == 5 }
    @r.lrange('list', 2, -1) { |r| r.should == ['1', '2', '3']; done }
  end
  #
  it "should be able to trim a list (LTRIM)" do
    @r.rpush "list", 'hello'
    @r.rpush "list", 'goodbye'
    @r.rpush "list", '1'
    @r.rpush "list", '2'
    @r.rpush "list", '3'
    @r.type('list') { |r| r.should == "list" }
    @r.llen('list') { |r| r.should == 5 }
    @r.ltrim 'list', 0, 1
    @r.llen('list') { |r| r.should == 2 }
    @r.lrange('list', 0, -1) { |r| r.should == ['hello', 'goodbye']; done }
  end
  #
  it "should be able to get a value by indexing into a list (LINDEX)" do
    @r.rpush "list", 'hello'
    @r.rpush "list", 'goodbye'
    @r.type('list') { |r| r.should == "list" }
    @r.llen('list') { |r| r.should == 2 }
    @r.lindex('list', 1) { |r| r.should == 'goodbye'; done }
  end
  #
  it "should be able to set a value by indexing into a list (LSET)" do
    @r.rpush "list", 'hello'
    @r.rpush "list", 'hello'
    @r.type('list') { |r| r.should == "list" }
    @r.llen('list') { |r| r.should == 2 }
    @r.lset('list', 1, 'goodbye') { |r| r.should == 'OK' }
    @r.lindex('list', 1) { |r| r.should == 'goodbye'; done }
  end
  #
  it "should be able to remove values from a list (LREM)" do
    @r.rpush "list", 'hello'
    @r.rpush "list", 'goodbye'
    @r.type('list') { |r| r.should == "list" }
    @r.llen('list') { |r| r.should == 2 }
    @r.lrem('list', 1, 'hello') { |r| r.should == 1 }
    @r.lrange('list', 0, -1) { |r| r.should == ['goodbye']; done }
  end

  it "should be able to pop values from a list and push them onto a temp list (RPOPLPUSH)" do
    @r.rpush "list", 'one'
    @r.rpush "list", 'two'
    @r.rpush "list", 'three'
    @r.type('list') { |r| r.should == "list" }
    @r.llen('list') { |r| r.should == 3 }
    @r.lrange('list', 0, -1) { |r| r.should == ['one', 'two', 'three'] }
    @r.lrange('tmp', 0, -1) { |r| r.should == [] }
    @r.rpoplpush('list', 'tmp') { |r| r.should == 'three' }
    @r.lrange('tmp', 0, -1) { |r| r.should == ['three'] }
    @r.rpoplpush('list', 'tmp') { |r| r.should == 'two' }
    @r.lrange('tmp', 0, -1) { |r| r.should == ['two', 'three'] }
    @r.rpoplpush('list', 'tmp') { |r| r.should == 'one' }
    @r.lrange('tmp', 0, -1) { |r| r.should == ['one', 'two', 'three']; done }
  end
  #
  it "should be able add members to a set (SADD)" do
    @r.sadd "set", 'key1'
    @r.sadd "set", 'key2'
    @r.type('set') { |r| r.should == "set" }
    @r.scard('set') { |r| r.should == 2 }
    @r.smembers('set') { |r| r.sort.should == ['key1', 'key2'].sort; done }
  end
  #
  it "should be able delete members to a set (SREM)" do
    @r.sadd "set", 'key1'
    @r.sadd "set", 'key2'
    @r.type('set') { |r| r.should == "set" }
    @r.scard('set') { |r| r.should == 2 }
    @r.smembers('set') { |r| r.sort.should == ['key1', 'key2'].sort }
    @r.srem('set', 'key1')
    @r.scard('set') { |r| r.should == 1 }
    @r.smembers('set') { |r| r.should == ['key2']; done }
  end
  #
  it "should be able to return and remove random key from set (SPOP)" do
    @r.sadd "set_pop", "key1"
    @r.sadd "set_pop", "key2"
    @r.spop("set_pop") { |r| r.should.not == nil }
    @r.scard("set_pop") { |r| r.should == 1; done }
  end
  #
  it "should be able to return random key without delete the key from a set (SRANDMEMBER)" do
    @r.sadd "set_srandmember", "key1"
    @r.sadd "set_srandmember", "key2"
    @r.srandmember("set_srandmember") { |r| r.should.not == nil }
    @r.scard("set_srandmember") { |r| r.should == 2; done }
  end
  #
  it "should be able count the members of a set (SCARD)" do
    @r.sadd "set", 'key1'
    @r.sadd "set", 'key2'
    @r.type('set') { |r| r.should == "set" }
    @r.scard('set') { |r| r.should == 2; done }
  end
  #
  it "should be able test for set membership (SISMEMBER)" do
    @r.sadd "set", 'key1'
    @r.sadd "set", 'key2'
    @r.type('set') { |r| r.should == "set" }
    @r.scard('set') { |r| r.should == 2 }
    @r.sismember('set', 'key1') { |r| r.should == true }
    @r.sismember('set', 'key2') { |r| r.should == true }
    @r.sismember('set', 'notthere') { |r| r.should == false; done }
  end
  #
  it "should be able to do set intersection (SINTER)" do
    @r.sadd "set", 'key1'
    @r.sadd "set", 'key2'
    @r.sadd "set2", 'key2'
    @r.sinter('set', 'set2') { |r| r.should == ['key2']; done }
  end
  #
  it "should be able to do set intersection and store the results in a key (SINTERSTORE)" do
    @r.sadd "set", 'key1'
    @r.sadd "set", 'key2'
    @r.sadd "set2", 'key2'
    @r.sinterstore('newone', 'set', 'set2') { |r| r.should == 1 }
    @r.smembers('newone') { |r| r.should == ['key2']; done }
  end
  #
  it "should be able to do set union (SUNION)" do
    @r.sadd "set", 'key1'
    @r.sadd "set", 'key2'
    @r.sadd "set2", 'key2'
    @r.sadd "set2", 'key3'
    @r.sunion('set', 'set2') { |r| r.sort.should == ['key1','key2','key3'].sort; done }
  end
  #
  it "should be able to do set union and store the results in a key (SUNIONSTORE)" do
    @r.sadd "set", 'key1'
    @r.sadd "set", 'key2'
    @r.sadd "set2", 'key2'
    @r.sadd "set2", 'key3'
    @r.sunionstore('newone', 'set', 'set2') { |r| r.should == 3 }
    @r.smembers('newone') { |r| r.sort.should == ['key1','key2','key3'].sort; done }
  end
  #
  it "should be able to do set difference (SDIFF)" do
     @r.sadd "set", 'a'
     @r.sadd "set", 'b'
     @r.sadd "set2", 'b'
     @r.sadd "set2", 'c'
     @r.sdiff('set', 'set2') { |r| r.should == ['a']; done }
   end
  #
  it "should be able to do set difference and store the results in a key (SDIFFSTORE)" do
     @r.sadd "set", 'a'
     @r.sadd "set", 'b'
     @r.sadd "set2", 'b'
     @r.sadd "set2", 'c'
     @r.sdiffstore('newone', 'set', 'set2')
     @r.smembers('newone') { |r| r.should == ['a']; done }
   end
  #
  it "should be able move elements from one set to another (SMOVE)" do
    @r.sadd 'set1', 'a'
    @r.sadd 'set1', 'b'
    @r.sadd 'set2', 'x'
    @r.smove('set1', 'set2', 'a') { |r| r.should == true }
    @r.sismember('set2', 'a') { |r| r.should == true }
    @r.delete('set1') { done }
  end
  #
  it "should be able to do crazy SORT queries" do
    # The 'Dogs' is capitialized on purpose
    @r['dog_1'] = 'louie'
    @r.rpush 'Dogs', 1
    @r['dog_2'] = 'lucy'
    @r.rpush 'Dogs', 2
    @r['dog_3'] = 'max'
    @r.rpush 'Dogs', 3
    @r['dog_4'] = 'taj'
    @r.rpush 'Dogs', 4
    @r.sort('Dogs', :get => 'dog_*', :limit => [0,1]) { |r| r.should == ['louie'] }
    @r.sort('Dogs', :get => 'dog_*', :limit => [0,1], :order => 'desc alpha') { |r| r.should == ['taj'] }
    @r.ping { done }
  end

  it "should be able to handle array of :get using SORT" do
    @r['dog:1:name'] = 'louie'
    @r['dog:1:breed'] = 'mutt'
    @r.rpush 'dogs', 1
    @r['dog:2:name'] = 'lucy'
    @r['dog:2:breed'] = 'poodle'
    @r.rpush 'dogs', 2
    @r['dog:3:name'] = 'max'
    @r['dog:3:breed'] = 'hound'
    @r.rpush 'dogs', 3
    @r['dog:4:name'] = 'taj'
    @r['dog:4:breed'] = 'terrier'
    @r.rpush 'dogs', 4
    @r.sort('dogs', :get => ['dog:*:name', 'dog:*:breed'], :limit => [0,1]) { |r| r.should == ['louie', 'mutt'] }
    @r.sort('dogs', :get => ['dog:*:name', 'dog:*:breed'], :limit => [0,1], :order => 'desc alpha') { |r| r.should == ['taj', 'terrier'] }
    @r.ping { done }
  end
  #
  it "should be able count the members of a zset" do
    @r.set_add "set", 'key1'
    @r.set_add "set", 'key2'
    @r.zset_add 'zset', 1, 'set'
    @r.zset_count('zset') { |r| r.should == 1 }
    @r.delete('set')
    @r.delete('zset') { done }
  end
  # 
  it "should be able add members to a zset" do
    @r.set_add "set", 'key1'
    @r.set_add "set", 'key2'
    @r.zset_add 'zset', 1, 'set'
    @r.zset_range('zset', 0, 1) { |r| r.should == ['set'] }
    @r.zset_count('zset') { |r| r.should == 1 }
    @r.delete('set')
    @r.delete('zset') { done }
  end
  # 
  it "should be able delete members to a zset" do
    @r.set_add "set", 'key1'
    @r.set_add "set", 'key2'
    @r.type?('set') { |r| r.should == "set" }
    @r.set_add "set2", 'key3'
    @r.set_add "set2", 'key4'
    @r.type?('set2') { |r| r.should == "set" }
    @r.zset_add 'zset', 1, 'set'
    @r.zset_count('zset') { |r| r.should == 1 }
    @r.zset_add 'zset', 2, 'set2'
    @r.zset_count('zset') { |r| r.should == 2 }
    @r.zset_delete 'zset', 'set'
    @r.zset_count('zset') { |r| r.should == 1 }
    @r.delete('set')
    @r.delete('set2')
    @r.delete('zset') { done }
  end
  # 
  it "should be able to get a range of values from a zset" do
    @r.set_add "set", 'key1'
    @r.set_add "set", 'key2'
    @r.set_add "set2", 'key3'
    @r.set_add "set2", 'key4'
    @r.set_add "set3", 'key1'
    @r.type?('set') { |r| r.should == 'set' }
    @r.type?('set2') { |r| r.should == 'set' }
    @r.type?('set3') { |r| r.should == 'set' }
    @r.zset_add 'zset', 1, 'set'
    @r.zset_add 'zset', 2, 'set2'
    @r.zset_add 'zset', 3, 'set3'
    @r.zset_count('zset') { |r| r.should == 3 }
    @r.zset_range('zset', 0, 3) { |r| r.should == ['set', 'set2', 'set3'] }
    @r.delete('set')
    @r.delete('set2')
    @r.delete('set3')
    @r.delete('zset') { done }
  end
  # 
  it "should be able to get a reverse range of values from a zset" do
    @r.set_add "set", 'key1'
    @r.set_add "set", 'key2'
    @r.set_add "set2", 'key3'
    @r.set_add "set2", 'key4'
    @r.set_add "set3", 'key1'
    @r.type?('set') { |r| r.should == 'set' }
    @r.type?('set2') { |r| r.should == 'set' }
    @r.type?('set3') { |r| r.should == 'set' }
    @r.zset_add 'zset', 1, 'set'
    @r.zset_add 'zset', 2, 'set2'
    @r.zset_add 'zset', 3, 'set3'
    @r.zset_count('zset') { |r| r.should == 3 }
    @r.zset_reverse_range('zset', 0, 3) { |r| r.should == ['set3', 'set2', 'set'] }
    @r.delete('set')
    @r.delete('set2')
    @r.delete('set3')
    @r.delete('zset') { done }
  end
  # 
  it "should be able to get a range by score of values from a zset" do
    @r.set_add "set", 'key1'
    @r.set_add "set", 'key2'
    @r.set_add "set2", 'key3'
    @r.set_add "set2", 'key4'
    @r.set_add "set3", 'key1'
    @r.set_add "set4", 'key4'
    @r.zset_add 'zset', 1, 'set'
    @r.zset_add 'zset', 2, 'set2'
    @r.zset_add 'zset', 3, 'set3'
    @r.zset_add 'zset', 4, 'set4'
    @r.zset_count('zset') { |r| r.should == 4 }
    @r.zset_range_by_score('zset', 2, 3) { |r| r.should == ['set2', 'set3'] }
    @r.delete('set')
    @r.delete('set2')
    @r.delete('set3')
    @r.delete('set4')
    @r.delete('zset') { done }
  end
  #
  it "should be able to get a score for a specific value in a zset (ZSCORE)" do
    @r.zset_add "zset", 23, "value"
    @r.zset_score("zset", "value") { |r| r.should == "23" }

    @r.zset_score("zset", "value2") { |r| r.should == nil }
    @r.zset_score("unknown_zset", "value") { |r| r.should == nil }

    @r.delete("zset") { done }
  end
  #
  it "should be able to increment a range score of a zset (ZINCRBY)" do
    # create a new zset
    @r.zset_increment_by "hackers", 1965, "Yukihiro Matsumoto"
    @r.zset_score("hackers", "Yukihiro Matsumoto") { |r| r.should == "1965" }

    # add a new element
    @r.zset_increment_by "hackers", 1912, "Alan Turing"
    @r.zset_score("hackers", "Alan Turing") { |r| r.should == "1912" }

    # update the score
    @r.zset_increment_by "hackers", 100, "Alan Turing" # yeah, we are making Turing a bit younger
    @r.zset_score("hackers", "Alan Turing") { |r| r.should == "2012" }

    @r.delete("hackers")
    @r.delete("i_am_not_a_zet") { done }
  end
  #
  it "should provide info (INFO)" do
    @r.info do |r|
      [:last_save_time, :redis_version, :total_connections_received, :connected_clients, :total_commands_processed, :connected_slaves, :uptime_in_seconds, :used_memory, :uptime_in_days, :changes_since_last_save].each do |x|
        r.keys.include?(x).should == true
      end
      done
    end
  end
  #
  it "should be able to flush the database (FLUSHDB)" do
    @r['key1'] = 'keyone'
    @r['key2'] = 'keytwo'
    @r.keys('*') { |r| r.sort.should == ['foo', 'key1', 'key2'] } #foo from before
    @r.flushdb
    @r.keys('*') { |r| r.should == []; done }
  end
  #
  it "should be able to SELECT database" do
    @r.select(15)
    @r.get('foo') { |r| r.should == nil; done }
  end
  #
  it "should be able to provide the last save time (LASTSAVE)" do
    @r.lastsave do |savetime|
      Time.at(savetime).class.should == Time
      Time.at(savetime).should <= Time.now
      done
    end
  end

  it "should be able to MGET keys" do
    @r['foo'] = 1000
    @r['bar'] = 2000
    @r.mget('foo', 'bar') { |r| r.should == ['1000', '2000'] }
    @r.mget('foo', 'bar', 'baz') { |r| r.should == ['1000', '2000', nil] }
    @r.ping { done }
  end

  it "should be able to mapped MGET keys" do
    @r['foo'] = 1000
    @r['bar'] = 2000
    @r.mapped_mget('foo', 'bar') { |r| r.should == { 'foo' => '1000', 'bar' => '2000'} }
    @r.mapped_mget('foo', 'baz', 'bar') { |r| r.should == { 'foo' => '1000', 'bar' => '2000'} }
    @r.ping { done }
  end

  it "should be able to MSET values" do
    @r.mset :key1 => "value1", :key2 => "value2"
    @r.get('key1') { |r| r.should == "value1" }
    @r.get('key2') { |r| r.should == "value2"; done }
  end

  it "should be able to MSETNX values" do
    @r.msetnx :keynx1 => "valuenx1", :keynx2 => "valuenx2"
    @r.mget('keynx1', 'keynx2') { |r| r.should == ["valuenx1", "valuenx2"] }

    @r["keynx1"] = "value1"
    @r["keynx2"] = "value2"
    @r.msetnx :keynx1 => "valuenx1", :keynx2 => "valuenx2"
    @r.mget('keynx1', 'keynx2') { |r| r.should == ["value1", "value2"]; done }
  end

  it "should bgsave" do
    @r.bgsave do |r|
      ['OK', 'Background saving started'].include?(r).should == true
      done
    end
  end

  it "should be able to ECHO" do
    @r.echo("message in a bottle\n") { |r| r.should == "message in a bottle\n"; done }
  end

  # Tests are disabled due uncatchable exceptions. We should use on_error callback,
  # intead of raising exceptions in random places.
  #
  # it "should raise error when invoke MONITOR" do
  #   # lambda { @r.monitor }.should.raise
  #   done
  # end
  # 
  # it "should raise error when invoke SYNC" do
  #   # lambda { @r.sync }.should.raise
  #   done
  # end

  it "should work with 10 commands" do
    @r.call_commands((1..10).map { |i|
                       ['get', "foo"]
                     }) do |rs|
      rs.length.should == 10
      rs.each { |r| r.should == "bar" }
      done
    end
  end
  it "should work with 1 command" do
    @r.call_commands([['get', "foo"]]) do |rs|
      rs.length.should == 1
      rs[0].should == "bar"
      done
    end
  end
  it "should work with zero commands" do
    @r.call_commands([]) do |rs|
      rs.should == []
      done
    end
  end
end
