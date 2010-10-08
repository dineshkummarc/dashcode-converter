module DashcodeConverter
  module Nib
    
    class NibItem

      attr_reader :name, :nib, :declaration
       
      def initialize(name, spec, nib)
        @name= name
        @nib= nib
        @declaration= from_spec(spec)
      end

      def fixup_html(html)
        if 'coherent.Button'==@classname
          html.name='button'
        end
        if @spec.include?('text')
          html.content= @spec['text']
        end
      end
      
      def from_spec(spec)
        @spec= spec
        nib_item= {}
        spec.each { |key, value|
          next if ["text", "view", "Class", "propertyValues"].include?(key)
        
          # translate Dashcode's onclick parameter into a target/action pair
          if "onclick"==key
            key="action"
            nib_item["target"]= "owner"
            nib.owner.add_action_method(value)
          end
        
          nib_item[key]= value
        }
        nib_item.merge!(spec['propertyValues']) if spec['propertyValues']
      
        parts= (spec['view']||spec['Class']).split(".")
        if 2==parts.length
          parts[0]= "coherent" if parts[0]=="DC"
          parts[1]= CLASSNAME_LOOKUP[parts[1]] if CLASSNAME_LOOKUP.include?(parts[1])
        end
      
        if self.respond_to?("adjust_declaration_for_#{parts[1]}")
          nib_item= self.send("adjust_declaration_for_#{parts[1]}", nib_item)
        end
        @classname= parts.join(".")
        values= nib_item.to_json(JSON_PARAMS)
        "'#{name}': #{@classname}(#{values})"
      end
      
    end
    
  end
end