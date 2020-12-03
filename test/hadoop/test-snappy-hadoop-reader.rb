require "minitest/autorun"
require "minitest/spec"
require "snappy"
require "stringio"

describe Snappy::Hadoop::Reader do
  before do
    @buffer = StringIO.new
    Snappy::Hadoop::Writer.new @buffer do |w|
      w << "foo"
      w << "bar"
      w << "baz"
      w << "quux"
    end
    @buffer.rewind
  end

  subject do
    Snappy::Hadoop::Reader.new @buffer
  end

  describe :initialize do
    it "should yield itself to the block" do
      yielded = nil
      returned = Snappy::Hadoop::Reader.new @buffer do |r|
        yielded = r
      end
      returned.must_equal yielded
    end
  end

  describe :io do
    it "should be a constructor argument" do
      subject.io.must_equal @buffer
    end

    it "should not receive `length' in initializing" do
      length = MiniTest::Mock.new.expect(:call, 0)
      @buffer.stub(:length, length) do
        Snappy::Hadoop::Reader.new @buffer
      end
      -> { length.verify }.must_raise MockExpectationError
    end
  end

  describe :each do
    before do
      Snappy::Hadoop::Writer.new @buffer do |w|
        w << "foo"
        w << "bar"
        w.dump!
        w << "baz"
        w << "quux"
      end
      @buffer.rewind
    end

    it "should yield each chunk" do
      chunks = []
      Snappy::Hadoop::Reader.new(@buffer).each do |chunk|
        chunks << chunk
      end
      chunks.must_equal ["foobar", "bazquux"]
    end
  end

  describe :read do
    before do
      Snappy::Hadoop::Writer.new @buffer do |w|
        w << "foo"
        w << "bar"
        w << "baz"
        w << "quux"
      end
      @buffer.rewind
    end

    it "should return the bytes" do
      Snappy::Hadoop::Reader.new(@buffer).read.must_equal "foobarbazquux"
    end
  end

  describe :each_line do
    before do
      Snappy::Hadoop::Writer.new @buffer do |w|
        w << "foo\n"
        w << "bar"
        w.dump!
        w << "baz\n"
        w << "quux\n"
      end
      @buffer.rewind
    end

    it "should yield each line" do
      lines = []
      Snappy::Hadoop::Reader.new(@buffer).each_line do |line|
        lines << line
      end
      lines.must_equal ["foo", "barbaz", "quux"]
    end
  end
end
