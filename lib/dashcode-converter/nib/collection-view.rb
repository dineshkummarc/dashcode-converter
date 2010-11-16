module DashcodeConverter
  
  module Nib
    
    class NibItem
      
      def adjust_declaration_for_CollectionView(decl)
        if decl.include?("dataArrayBinding")
          decl.delete("dataArray")

          array_controller_name= nib.unique_name(name[1..-1])
          array_controller= NibItem.new(array_controller_name, nib)
          array_controller.classname="coherent.ArrayController"
          array_controller.spec= {
              "contentBinding" => decl.delete("dataArrayBinding")
            }
          nib.add_item(array_controller)
          nib.add_owner_reference(array_controller_name,array_controller_name)
          
          decl["contentBinding"]= {
            :keypath => "#{array_controller_name}.arrangedObjects"
          }
          decl["selectionIndexesBinding"]= {
            :keypath => "#{array_controller_name}.selectionIndexes"
          }
        end
        
        decl.delete("useDataSource")
        decl.delete("sampleRows")
        decl.delete("labelElementId")
        decl.delete("listStyle")
        decl["content"]= decl.delete("dataArray") if decl.include?("dataArray")
        decl
      end

      # Need to fix up the bindings for CollectionViews because Coherent before
      # version 3.0 used a whacky star notation for binding to values in the
      # list view.
      def fixup_html_for_CollectionView(html)
        template= View.new(nib.unique_name("#{name[1..-1]}Item"), nib)
        template.is_template= true
        nib.add_view(template)
        @spec["viewTemplate"]= JavascriptCode("REF('#{template.name}')")
        
        html.css("[id]").each { |node|
          next unless (item= view.items_by_id["##{node["id"]}"])
          view.remove_item(item)
          template.add_item(item)
        }
      end
      
    end
    
  end
  
end
