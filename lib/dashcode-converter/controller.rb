module DashcodeConverter
  
  class Controller

    DECL_TEMPLATE= <<-EOF
        /*import coherent*/

        <%=namespace%>.<%=name%>= Class.create(coherent.ViewController, {
        
        <%=@methods.join(",\n").indent(INDENT)%>
        
        });
    EOF
    
    attr_reader :name, :namespace
    
    def initialize(name, namespace=nil)
      @name= "#{name.capitalize}Controller"
      @namespace= namespace || name
      @methods= []
    end
    
    def add_action_method(name)
      @methods << "#{name}: function(sender)\n{\n}"
    end

    def declaration
      return @declaration if @declaration
      @declaration= ERB.new(DECL_TEMPLATE.remove_indent).result binding
    end
  end
  
end
