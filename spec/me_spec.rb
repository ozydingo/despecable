require "spec_helper"

describe Despecable::Me do
  describe ".doit" do
    it "converts an integer" do
      params = Despecable::Me.new(x: "42").doit{integer :x}
      expect(params[:x]).to eq(42)
    end

    it "converts an float" do
      params = Despecable::Me.new(x: "3.14159").doit{float :x}
      expect(params[:x]).to eq(3.14159)
    end

    it "converts an string" do
      params = Despecable::Me.new(x: "hello").doit{string :x}
      expect(params[:x]).to eq("hello")
    end

    it "converts a string boolean" do
      params = Despecable::Me.new(t: "true", f: "false").doit do
        boolean :t
        boolean :f
      end
      expect(params[:t]).to eq(true)
      expect(params[:f]).to eq(false)
    end

    it "converts a numeric boolean" do
      params = Despecable::Me.new(t: "1", f: "0").doit do
        boolean :t
        boolean :f
      end
      expect(params[:t]).to eq(true)
      expect(params[:f]).to eq(false)
    end

    it "converts a date" do
      params = Despecable::Me.new(when: '2012-12-31').doit{date :when}
      expect(params[:when]).to eq(Date.rfc3339('2012-12-31T00:00:00+00:00'))
    end

    it "converts a datetime" do
      params = Despecable::Me.new(when: '2009-06-19T00:00:00-04:00').doit{datetime :when}
      expect(params[:when]).to eq(DateTime.rfc3339('2009-06-19T00:00:00-04:00'))
    end

    it "uses a custom converter, still allowing a default" do
      params = Despecable::Me.new(doubled: '1').doit do
        custom :doubled do |name, value, options|
          value.to_i * 2
        end
        custom :default, default: 0 do |name, value, options|
          value.to_i * 2
        end
      end
      expect(params[:doubled]).to eq(2)
      expect(params[:default]).to eq(0)
    end

    it "arraifies a custom param" do
      params = Despecable::Me.new(doubled: '1,2').doit do
        custom :doubled, array: true do |name, value, options|
          value.to_i * 2
        end
      end
      expect(params[:doubled]).to eq([2,4])
    end

    it "raises for a incorrect-case string" do
      me = Despecable::Me.new(x: "hello")
      expect{me.doit{string :x, in: ["Hello"]}}.to raise_error do |error|
        expect(error).to be_a(Despecable::IncorrectParameterError)
        expect(error.parameters).to eq(["x"])
      end
    end

    it "allows mixed case strings on case: false" do
      params = Despecable::Me.new(x: "hello").doit{string :x, in: ["Hello"], case: false}
      expect(params[:x]).to eq("hello")
    end

    it "raises for a incorrect-case string" do
      me = Despecable::Me.new(x: "hello")
      expect{me.doit{any :x, in: ["Hello"]}}.to raise_error do |error|
        expect(error).to be_a(Despecable::IncorrectParameterError)
        expect(error.parameters).to eq(["x"])
      end
    end

    it "allows mixed case strings on case: false using 'any'" do
      params = Despecable::Me.new(x: "hello").doit{any :x, in: ["Hello"], case: false}
      expect(params[:x]).to eq("hello")
    end

    it "matches a string matching a Range length" do
      params = Despecable::Me.new(x: "hello").doit{string :x, length: 2..8}
      expect(params[:x]).to eq("hello")
    end

    it "matches a string matching a int length" do
      params = Despecable::Me.new(x: "hello").doit{string :x, length: 5}
      expect(params[:x]).to eq("hello")
    end

    it "raises for a bad-length string" do
      me = Despecable::Me.new(x: "hello")
      expect{me.doit{string :x, length: 2}}.to raise_error do |error|
        expect(error).to be_a(Despecable::IncorrectParameterError)
        expect(error.parameters).to eq(["x"])
      end
    end

    it "raises for a bad integer" do
      me = Despecable::Me.new(x: "hello")
      expect{me.doit{integer :x}}.to raise_error do |error|
        expect(error).to be_a(Despecable::InvalidParameterError)
        expect(error.parameters).to eq(["x"])
      end
    end

    it "raises for a bad float" do
      me = Despecable::Me.new(x: "hello")
      expect{me.doit{float :x}}.to raise_error do |error|
        expect(error).to be_a(Despecable::InvalidParameterError)
        expect(error.parameters).to eq(["x"])
      end
    end

    it "raises for a bad boolean" do
      me = Despecable::Me.new(t: "T")
      expect{me.doit{boolean :t}}.to raise_error do |error|
        expect(error).to be_a(Despecable::InvalidParameterError)
        expect(error.parameters).to eq(["t"])
      end
    end

    it "raises for a bad date" do
      me = Despecable::Me.new(when: "tomorrow")
      expect{me.doit{boolean :when}}.to raise_error do |error|
        expect(error).to be_a(Despecable::InvalidParameterError)
        expect(error.parameters).to eq(["when"])
      end
    end

    it "raises for a bad datetime" do
      me = Despecable::Me.new(when: "2012-02-01")
      expect{me.doit{boolean :when}}.to raise_error do |error|
        expect(error).to be_a(Despecable::InvalidParameterError)
        expect(error.parameters).to eq(["when"])
      end
    end

    context "when a param is required" do
      it "raises when it is missing" do
        me = Despecable::Me.new(x: "hello")
        expect do
          me.doit do
            string :x
            string :y, required: true
          end
        end.to raise_error do |error|
          expect(error).to be_a(Despecable::MissingParameterError)
          expect(error.parameters).to eq(["y"])
        end
      end

      it "passes when it is provided" do
        me = Despecable::Me.new(x: "hello", y: "world")
        expect do
          me.doit do
            string :x
            string :y, required: true
          end
        end.to_not raise_error
      end
    end

    context "when a parameter has a set of acceptable values" do
      it "raises when a bad value is passed" do
        me = Despecable::Me.new(x: "goodbye")
        expect do
          me.doit{ string :x, in: ["hello", "hi"]}
        end.to raise_error do |error|
          expect(error).to be_a(Despecable::IncorrectParameterError)
          expect(error.parameters).to eq(["x"])
        end
      end

      it "passes when a correct value is passed" do
        me = Despecable::Me.new(x: "hi")
        expect do
          me.doit{ string :x, in: ["hello", "hi"]}
        end.to_not raise_error
      end
    end

    context "when a param is an array" do
      it "parses a single value as an array" do
        me = Despecable::Me.new(x: "hi")
        params = me.doit{string :x, array: true}
        expect(params[:x]).to eq(["hi"])
      end

      it "parses multiple values as an array" do
        me = Despecable::Me.new(x: "hello,world")
        params = me.doit{string :x, array: true}
        expect(params[:x]).to eq(["hello", "world"])
      end
    end

    context "when a param is arrayable" do
      it "does not parse a single value as an array" do
        me = Despecable::Me.new(x: "hi")
        params = me.doit{string :x, arrayable: true}
        expect(params[:x]).to eq("hi")
      end

      it "parses multiple values as an array" do
        me = Despecable::Me.new(x: "hello,world")
        params = me.doit{string :x, arrayable: true}
        expect(params[:x]).to eq(["hello", "world"])
      end
    end

    context "with a default parameter value" do
      it "uses the default when a value is not provided" do
        me = Despecable::Me.new({})
        params = me.doit{string :x, default: "hello"}
        expect(params[:x]).to eq("hello")
      end

      it "ignores the default when a value is provided" do
        me = Despecable::Me.new(x: "world")
        params = me.doit{string :x, default: "hello"}
        expect(params[:x]).to eq("world")
      end
    end
  end
end
