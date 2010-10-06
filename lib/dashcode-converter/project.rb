module DashcodeConverter

  CSS_IMAGE_URL_REGEX= /url\("?(.*\.(jpg|png|gif))"?\)/
  
  class Project

    JSON_PARAMS= {
      :indent=> "  ",
      :object_nl=> "\n",
      :array_nl=> "\n",
      :space=> " "
    }
    
    CLASSNAME_LOOKUP= {
      "Text" => "View",
      "PushButton" => "Button",
      "List" => "CollectionView"
    }
    
    NIB_TEMPLATE= ERB.new %q{
      NIB("<%=@name%>", {
      <% (nib_items["views"]||{}).each do |view_name, decl| %>
        "<%=view_name%>": VIEW({
        <% decl.each do |id, part| %>
            "#<%=id%>": <%=nib_item_spec(part)%>,
        <% end %>
        }),
      <% end %>
      // Everything else
      <% nib_items.each do |item_name, decl| %>
        <% next if 'views'==item_name %>
        "<%=item_name%>": <%=nib_item_spec(decl)%>,
      <% end %>
      });
    }
          
    def initialize(project_bundle)
      @project_bundle= File.expand_path(project_bundle)
      @name= File.basename(@project_bundle, ".*")
      @output_folder= File.expand_path(File.join("out", "#{@name}.jsnib"))
      @parts_spec_path= File.join(@project_bundle, "project", "safari", "Parts", "setup.js")
      @datasources_spec_path= File.join(@project_bundle, "project", "Parts", "datasources.js")
      @css_path= File.join(@project_bundle, "project", "safari", "main.css")
      @markup_path= File.join(@project_bundle, "project", "index.html")
      @images_folder= File.join(@output_folder, "images")
      @owner_methods= []
    end

    def path_relative_to_folder(path, folder)
      path= File.expand_path(path)
      outputFolder= File.expand_path(folder).to_s
  
      # Remove leading slash and split into parts
      file_parts= path.slice(1..-1).split('/');
      output_parts= outputFolder.slice(1..-1).split('/');

      common_prefix_length= 0

      file_parts.each_index { |i|
        common_prefix_length= i
        break if file_parts[i]!=output_parts[i]
      }

      return '../'*(output_parts.length-common_prefix_length) + file_parts[common_prefix_length..-1].join('/')
    end

    def relative_path(path)
      path_relative_to_folder(path, @output_folder)
    end
    
    def adjust_declaration_for_CollectionView(decl)
      decl.delete("useDataSource")
      decl.delete("sampleRows")
      decl.delete("labelElementId")
      decl.delete("listStyle")
      decl.delete("dataArray")
      decl
    end
    
    def nib_item_spec(decl)
      spec= {}
      decl.each { |key, value|
        next if ["text", "view", "Class", "propertyValues"].include?(key)
        
        # translate Dashcode's onclick parameter into a target/action pair
        if "onclick"==key
          key="action"
          spec["target"]= "owner"
          @owner_methods << value
        end
        
        spec[key]= value
      }
      spec.merge!(decl['propertyValues']) if decl['propertyValues']
      
      parts= (decl['view']||decl['Class']).split(".")
      parts[0]= "coherent" if parts[0]=="DC"
      parts[1]= CLASSNAME_LOOKUP[parts[1]] if CLASSNAME_LOOKUP.include?(parts[1])

      if self.respond_to?("adjust_declaration_for_#{parts[1]}")
        spec= self.send("adjust_declaration_for_#{parts[1]}", spec)
      end
      values= spec.to_json(JSON_PARAMS)
      values= values.split("\n").join("\n                ")
      "#{parts.join(".")}(#{values})"
    end
    
    def doc
      return @doc if @doc
      
      html= File.read(@markup_path)
      @doc= Nokogiri::HTML(html)
    end

    def nib_items_from_path(path)
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
    
    def nib_items
      return @nib_items if @nib_items
      
      @nib_items= {
        'views' => {
          @name => nib_items_from_path(@parts_spec_path)
        }
      }
      @nib_items.merge!(nib_items_from_path(@datasources_spec_path))
    end
    
    def css
      text= File.read(@css_path)
      dirname= File.dirname(@css_path)
      text.gsub!(CSS_IMAGE_URL_REGEX) { |match|
        image_file= File.join(dirname, $1)

        if (!File.exists?(image_file))
          match
        else
          new_image_file= File.join(@images_folder, File.basename(image_file))
          FileUtils.cp image_file, new_image_file
          "url(\"#{relative_path(new_image_file)}\")"
        end
      }
      text
    end
    
    def nib
      NIB_TEMPLATE.result binding
    end
    
    def fixup_html
      base= doc.css("base")
      base= base ? base.attribute("href") : nil
      
      content= doc.css("body > *:first-child")[0]
      content.traverse { |node|
        next unless node.attributes
        node.attributes.each { |attr, value|
          if 0==attr.index("apple-")
            node.remove_attribute(attr)
          end
        }
      }
      
      dirname= File.dirname(@markup_path)
      dirname= File.join(dirname, base) if base
      
      content.css("[src]").each { |node|
        image_file= File.join(dirname, node.attribute('src'))
        new_image_file= File.join(@images_folder, File.basename(image_file))
        FileUtils.cp image_file, new_image_file
        node["src"]= relative_path(new_image_file)
      }
      
      nib_items.each { |id, definition|
        html= doc.css("##{id}")[0]
        if definition['view']=='DC.PushButton'
          html.name='button'
        end
        if definition.include?('text')
          html.content= definition['text']
        end
      }
    end
    
    def convert
      fixup_html
      
      FileUtils.mkdir_p(@output_folder)
      FileUtils.mkdir_p(@images_folder)
      
      Dir.chdir(@output_folder) do
        File.open("#{@name}.js", "w") { |nib_file|
          nib_file << nib
        }
        File.open("#{@name}.css", "w") { |css_file|
          css_file << css
        }
        File.open("#{@name}.html", "w") { |html_file|
          html_file << doc.css("body > *:first-child")[0].serialize
        }
      end
    end
    
  end
  
end
