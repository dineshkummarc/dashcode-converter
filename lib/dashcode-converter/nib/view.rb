module DashcodeConverter
  module Nib
    
    class View
    
      DECL_TEMPLATE= <<-EOF
          '<%=name%>': VIEW({
          <%=views.join(",\n\n").indent(INDENT)%>
          })
      EOF
      
      attr_reader :name, :nib, :declaration, :items
      
      def initialize(name, spec, nib)
        @name= name
        @nib= nib
        @items= []
        from_spec(spec)
      end

      def from_spec(spec)
        views= spec.map { |id, part_spec|
          item= NibItem.new("##{id}", part_spec, nib)
          @items << item
          item.declaration
        }
        @declaration= ERB.new(DECL_TEMPLATE.remove_indent).result binding
      end
      
    end
    
  end
end