module DashcodeConverter
  
  class Controller

    FUNCTION_BODY_REGEX= /function \w+\(([^)]*)\)\s*\{(.*)\}\s*$/m
    
    ACTION_METHOD_CODE_DOC= <<-EOF
      /**
          <%=namespace%>.<%=name%>#<%=methodname%>(sender[, argument])
          
          - sender (coherent.View): The view that sent this action.
          - argument (Any): An argument, usually set by the `argumentBinding`.
          
          This is an action method send by a view in your NIB.
      **/
    EOF
    
    DECL_TEMPLATE= <<-EOF
        /*import coherent*/

        <%=namespace%>.<%=name%>= Class.create(coherent.ViewController, {
        
        <%=@methods.join(",\n").indent(INDENT)%>
        
        });
    EOF
    
    attr_reader :name, :namespace
    
    def initialize(name, namespace=nil, scripts=nil)
      @name= "#{name.capitalize}Controller"
      @namespace= namespace || name
      @methods= []
      @scripts= scripts
    end
    
    def add_action_method(methodname)
      doc= ERB.new(ACTION_METHOD_CODE_DOC.remove_indent).result binding

      match= FUNCTION_BODY_REGEX.match(@scripts[methodname].to_s)
      unless match
        @methods << "#{doc}\n#{methodname}: function(sender, argument)\n{\n}"
        return
      end
      
      args= match[1].split(/\s*,\*/)
      body= match[2]

      if args.include?('event') && body[/\bevent\b/]
        body= "\n    var event= coherent.EventLoop.currentEvent;\n#{body}"
      end
      # Fixup any crazy DC references
      body.gsub!(/\bDC\./, "coherent.")
      # Fixup datasources
      body.gsub!(/dashcode\.getDataSource\(['"](\w+)['"]\)/) { |match|
        "this.#{$1}"
      }
      @methods << "#{doc}\n#{methodname}: function(sender, argument)\n{#{body}}"
    end

    def declaration
      return @declaration if @declaration
      @declaration= ERB.new(DECL_TEMPLATE.remove_indent).result binding
    end
  end
  
end
