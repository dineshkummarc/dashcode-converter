module DashcodeConverter
  
  module Nib
    
    class NibItem
      
      def adjust_declaration_for_CollectionView(decl)
        if decl.include?("dataArrayBinding")
          decl.delete("dataArray")
          decl["contentBinding"]= decl.delete("dataArrayBinding")
        end

        decl.delete("useDataSource")
        decl.delete("sampleRows")
        decl.delete("labelElementId")
        decl.delete("listStyle")
        decl["content"]= decl.delete("dataArray") if decl.include?("dataArray")
        decl
      end
      
    end
    
  end
  
end
