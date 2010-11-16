module DashcodeConverter
  
  module Nib

    CLASSNAME_LOOKUP= {
      "Text" => "View",
      "PushButton" => "Button",
      "List" => "CollectionView"
    }

    class Nib

      DECL_TEMPLATE= <<-EOF
          /*import coherent*/
          NIB('<%=name%>', {
            
          <%=items_array.join(",\n\n").indent(INDENT)%>,
          
          <%=_owner_decl.indent(INDENT)%>
          });
      EOF
      
      attr_reader :name, :items, :views, :owner
      
      def initialize(name, owner)
        @name= name
        @owner= owner
        @owner_references= {}
        @items= {}
        @views= []
        add_owner_reference('view', name)
      end
      
      def add_view(view)
        items[view.name]= view
        views << view
      end
      
      def add_item(item)
        items[item.name]= item
      end
      
      def add_view_from_path(path, name=@name)
        view= View.new(name, self)
        view.parse_spec(parse_parts(path))
        add_view(view)
      end
      
      def add_datasources_from_path(path)
        datasources= parse_parts(path)
        datasources.each { |name, spec|
          datasource= NibItem.new(name, self)
          datasource.parse_spec(spec)
          items[name]= datasource
          add_owner_reference(name, name)
        }
      end
      
      def add_owner_reference(name, reference)
        @owner_references[name]= JavascriptCode("REF('#{reference}')")
      end
      
      def declaration
        return @declaration if @declaration
        
        items_array= items.map { |key, value| value.declaration }
        
        @declaration= ERB.new(DECL_TEMPLATE.remove_indent).result binding
      end
      
      def parse_parts(path)
        in_json= false
        json= "{\n"
        text= File.read(path)
        text.each { |line|
          if in_json
            json << line
            next
          end

          next unless (line =~ /dashcodePartSpecs/ || line =~ /dashcodeDataSources/)
          in_json= true
        }
        JSON.parse(json.gsub(/;$/,''))
      end

      def unique_name(basename)
        index=0
        name= basename
        while items.include?(name)
          index+=1
          name= "#{basename}#{index}"
        end
        name
      end
      
      def _owner_decl
        "owner: #{@owner_references.to_json(JSON_PARAMS)}"
      end
      
    end

  end
  
end

require 'dashcode-converter/nib/nib-item'
require 'dashcode-converter/nib/view'
require 'dashcode-converter/nib/collection-view'
