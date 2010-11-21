module DashcodeConverter
  
  module Nib
    
    MAIN_VIEW_NAME= "main-view"
    
    CLASSNAME_LOOKUP= {
      "Text" => "View",
      "PushButton" => "Button",
      "List" => "CollectionView",
      "ImageLayout" => "Image"
    }

    class Nib

      DECL_TEMPLATE= <<-EOF
          /*jsl:import coherent*/
          
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
      end
      
      def add_view(view)
        items[view.name]= view
        views << view
        if (!view.is_template)
          if view.is_primary
            add_owner_reference('view', view.name)
          else
            add_owner_reference(view.name, view.name)
          end
        end
      end
      
      def add_item(item)
        items[item.name]= item
      end
      
      def add_view_from_path(path, name, primary)
        view= View.new(name, self, primary)
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
