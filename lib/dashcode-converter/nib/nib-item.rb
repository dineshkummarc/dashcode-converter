module DashcodeConverter
  module Nib
    
    class NibItem

      attr_reader :name, :nib
      attr_accessor :view
       
      def initialize(name, spec, nib)
        @name= name
        @nib= nib
        @view= nil
        @spec= from_spec(spec)
      end

      def declaration
        return @declaration if @declaration
        
        values= @spec.to_json(JSON_PARAMS)
        @declaration= "'#{name}': #{@classname}(#{values})"
      end
      
      def fixup_html(html)
        if 'coherent.Button'==@classname
          html.name='button'
        end
        if @spec.include?('text')
          html.content= @spec.delete('text')
        end

        # allow class specific fixups
        if self.respond_to?("fixup_html_for_#{@fixupname}")
          self.send("fixup_html_for_#{@fixupname}", html)
        end
      end
      
      def from_spec(spec)
        nib_item= {}
        spec.each { |key, value|
          next if ["view", "Class", "propertyValues"].include?(key)
        
          # translate Dashcode's onclick parameter into a target/action pair
          if "onclick"==key
            key="action"
            nib_item["target"]= "owner"
            nib.owner.add_action_method(value)
          end

          nib_item[key]= value
        }
        nib_item.merge!(spec['propertyValues']) if spec['propertyValues']

        nib_item.each { |key, value|
          # rewrite relative bindings to use representedObject which is the
          # way this works in Coherent 3.0.
          if key =~ /Binding$/ && value.include?("keypath")
            value["keypath"]= value["keypath"].gsub(/^\*\./, "representedObject.")
          end
        }

        parts= (spec['view']||spec['Class']).split(".")
        if 2==parts.length
          parts[0]= "coherent" if parts[0]=="DC"
          parts[1]= CLASSNAME_LOOKUP[parts[1]] if CLASSNAME_LOOKUP.include?(parts[1])
        end
      
        @fixupname= parts[-1]

        if self.respond_to?("adjust_declaration_for_#{@fixupname}")
          nib_item= self.send("adjust_declaration_for_#{@fixupname}", nib_item)
        end

        @classname= parts.join(".")
        nib_item
      end
      
    end
    
  end
end