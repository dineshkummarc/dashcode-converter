module DashcodeConverter
  
  class Scripts
    
    def initialize(folder)
      @context= V8::Context.new
      @context.load(File.join(File.dirname(__FILE__), "env.js"))
      Dir.glob(File.join(folder, "**", "*.js")) { |file|
        @context.load(file)
      }
    end
    
    def [](name)
      @context[name]
    end
    
  end
  
end
