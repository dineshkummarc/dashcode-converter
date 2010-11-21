module DashcodeConverter
  module Nib
    
    class View
    
      DECL_TEMPLATE= <<-EOF
          '<%=name%>': <%=is_template ? "VIEW_TEMPLATE" : "VIEW"%>({
          <%=views.join(",\n\n").indent(INDENT)%>
          })
      EOF
      
      attr_reader :name, :nib, :items, :items_by_id
      attr_accessor :is_template, :is_primary
      
      def initialize(name, nib, primary=false)
        @name= name
        @nib= nib
        @items= []
        @items_by_id= {}
        @is_primary= primary
      end

      def remove_item(item)
        @items_by_id.delete(item.name)
        @items.delete(item)
      end
      
      def add_item(item)
        item.view= self
        @items_by_id[item.name]= item
        @items << item
      end
      
      def parse_spec(spec)
        spec.each { |id, part_spec|
          item= NibItem.new("##{id}", nib)
          item.parse_spec(part_spec)
          add_item(item)
        }
      end
      
      def declaration
        return @declaration if @declaration
        
        views= items.map { |item| item.declaration }
        @declaration= ERB.new(DECL_TEMPLATE.remove_indent).result binding
      end
      
    end
    
  end
end