require File.expand_path('../../../spec_helper', __FILE__)
require File.expand_path('../fixtures/classes', __FILE__)

describe "Numeric#step with [stop, step]" do
  before(:each) do
    @obj = NumericSpecs::Subclass.new
  end
  
  it "raises an ArgumentError when step is 0" do
    lambda { @obj.step(5, 0) {} }.should raise_error(ArgumentError)
  end
  
  ruby_version_is "" ... "1.8.7" do
    it "raises no LocalJumpError when passed no block and self > stop" do
      @stop = mock("Stop value")
      @step = mock("Step value")
      @step.should_receive(:>).with(0).and_return(true)
      
      @obj.should_receive(:>).with(@stop).and_return(true)
      
      lambda { @obj.step(@stop, @step) }.should_not raise_error(LocalJumpError)
    end

    it "raises a LocalJumpError when passed no block and self < stop" do
      @stop = mock("Stop value")
      @step = mock("Step value")
      @step.should_receive(:>).with(0).and_return(true)
      
      @obj.should_receive(:>).with(@stop).and_return(false)
      
      lambda { @obj.step(@stop, @step) }.should raise_error(LocalJumpError)
    end
  end

  ruby_version_is "1.8.7" do
    it "returns an Enumerator when passed no block and self > stop" do
      @stop = mock("Stop value")
      @step = mock("Step value")
      
      @obj.step(@stop, @step).should be_an_instance_of(enumerator_class)
    end

    it "returns an Enumerator when passed no block and self < stop" do
      @stop = mock("Stop value")
      @step = mock("Step value")
      
      @obj.step(@stop, @step).should be_an_instance_of(enumerator_class)
    end

    it "returns an Enumerator that uses the given step" do
      0.step(5, 2).to_a.should == [0, 2, 4]
    end
  end
  
  it "increments self (using #+) until self > stop when step > 0" do
    values = []
    
    @stop = mock("Stop value")
    @step = mock("Step value")
    @step.should_receive(:>).with(0).and_return(true)
    
    # Stepping 3 times
    @obj.should_receive(:>).with(@stop).and_return(false, false, false, true)
    @obj.should_receive(:+).with(@step).and_return(@obj, @obj, @obj)
    
    @obj.step(@stop, @step) { |i| values << i }
    
    values.should == [@obj, @obj, @obj]
  end
  
  it "decrements self (using #+) until self < stop when step < 0" do
    values = []
    
    @stop = mock("Stop value")
    @step = mock("Step value")
    @step.should_receive(:>).with(0).and_return(false)
    
    # Stepping 3 times
    @obj.should_receive(:<).with(@stop).and_return(false, false, false, true)
    # Calling #+ with negative step decrements self
    @obj.should_receive(:+).with(@step).and_return(@obj, @obj, @obj)
    
    @obj.step(@stop, @step) { |i| values << i }
    
    values.should == [@obj, @obj, @obj]
  end
end

describe "Numeric#step with [stop, step] when self, stop and step are Fixnums" do
  it "raises an ArgumentError when step is 0" do
    lambda { 1.step(5, 0) {} }.should raise_error(ArgumentError)
  end

  it "yields only Fixnums" do
    1.step(5, 1) { |x| x.should be_kind_of(Fixnum) }
  end
  
  it "defaults to step = 1" do
    result = []
    1.step(5) { |x| result << x }
    result.should == [1, 2, 3, 4, 5]
  end
end

describe "Numeric#step with [stop, +step] when self, stop and step are Fixnums" do
  it "yields while increasing self by step until stop is reached" do
    result = []
    1.step(5, 1) { |x| result << x }
    result.should == [1, 2, 3, 4, 5]
  end

  it "yields once when self equals stop" do
    result = []
    1.step(1, 1) { |x| result << x }
    result.should == [1]
  end

  it "does not yield when self is greater than stop" do
    result = []
    2.step(1, 1) { |x| result << x }
    result.should == []
  end
end
  
describe "Numeric#step with [stop, -step] when self, stop and step are Fixnums" do
  it "yields while decreasing self by step until stop is reached" do
    result = []
    5.step(1, -1) { |x| result << x }
    result.should == [5, 4, 3, 2, 1]
  end

  it "yields once when self equals stop" do
    result = []
    5.step(5, -1) { |x| result << x }
    result.should == [5]
  end

  it "does not yield when self is less than stop" do
    result = []
    1.step(5, -1) { |x| result << x }
    result.should == []
  end
end

describe "Numeric#step with [stop, step] when self, stop or step is a Float" do
  it "raises an ArgumentError when step is 0" do
    lambda { 1.1.step(2, 0.0) {} }.should raise_error(ArgumentError)
  end
  
  it "yields only Floats" do
    1.5.step(5, 1) { |x| x.should be_kind_of(Float) }
    1.step(5.0, 1) { |x| x.should be_kind_of(Float) }
    1.step(5, 1.0) { |x| x.should be_kind_of(Float) }
  end
end

describe "Numeric#step with [stop, +infinity]" do
  ruby_bug "#781", "1.8.7" do
    it "yields once if self < stop" do
      result = []
      42.step(100, 1.0/0.0)              { |x| result << x }
      42.step(1.0/0.0, 1.0/0.0)          { |x| result << x }
      result.should == [42, 42]
    end

    it "yields once when self equals stop" do
      result = []
      42.step(42, 1.0/0.0)               { |x| result << x }
      (1.0/0.0).step(1.0/0.0, 1.0/0.0)   { |x| result << x }
      result.should == [42, 1.0/0.0]
    end
  end

  ruby_bug "#3945", "1.9.2" do
    it "does not yield when self > stop" do
      result = []
      100.step(42, 1.0/0.0)              { |x| result << x }
      42.step(-1.0/0.0, 1.0/0.0)         { |x| result << x }
      result.should == []
    end
  end
end

describe "Numeric#step with [stop, +step] when self, stop or step is a Float" do
  it "yields while increasing self by step until stop is reached" do
    result = []
    1.5.step(5, 1) { |x| result << x }
    result.should == [1.5, 2.5, 3.5, 4.5]
  end

  it "yields once when self equals stop" do
    result = []
    1.5.step(1.5, 1) { |x| result << x }
    result.should == [1.5]
  end

  it "does not yield when self is greater than stop" do
    result = []
    2.5.step(1.5, 1) { |x| result << x }
    result.should == []
  end
end

describe "Numeric#step with [stop, -infinity]" do
  ruby_bug "#3945", "1.9.2" do
    it "yields once if self > stop" do
      result = []
      42.step(6, -1.0/0.0)               { |x| result << x }
      42.step(-1.0/0.0, -1.0/0.0)        { |x| result << x }
      result.should == [42, 42]
    end

    it "yields once when self equals stop" do
      result = []
      42.step(42, -1.0/0.0)              { |x| result << x }
      (1.0/0.0).step(1.0/0.0, -1.0/0.0)  { |x| result << x }
      result.should == [42, 1.0/0.0]
    end
  end

  ruby_bug "#781", "1.8.7" do
    it "does not yield when self > stop" do
      result = []
      42.step(100, -1.0/0.0)             { |x| result << x }
      42.step(1.0/0.0, -1.0/0.0)         { |x| result << x }
      result.should == []
    end
  end
end

describe "Numeric#step with [stop, -step] when self, stop or step is a Float" do
  it "yields while decreasing self by step until stop is reached" do
    result = []
    5.step(1.5, -1) { |x| result << x }
    result.should == [5.0, 4.0, 3.0, 2.0]
  end

  it "yields once when self equals stop" do
    result = []
    1.5.step(1.5, -1) { |x| result << x }
    result.should == [1.5]
  end

  it "does not yield when self is less than stop" do
    result = []
    1.step(5, -1.5) { |x| result << x }
    result.should == []
  end
end

describe "Numeric#step" do
  it "doesn't catch errors" do
    lambda{ 1.step(2) { raise ArgumentError, "oups" }}.should raise_error(ArgumentError, "oups")
    lambda{ 1.step(2) { raise TypeError, "oups" }    }.should raise_error(TypeError, "oups")
  end
end
