module DashcodeConverter

  CSS_IMAGE_URL_REGEX= /url\("?(.*\.(jpg|png|gif))"?\)/
  BUNDLE_EXTENSION= "jsnib"
  
  class Project
    
    attr_accessor :namespace
    
    def initialize(project_bundle, output_folder)
      @project_bundle= File.expand_path(project_bundle)
      @name= File.basename(@project_bundle, ".*")
      @namespace= @name
      @output_folder= File.expand_path(File.join(output_folder, "#{@name}.#{BUNDLE_EXTENSION}"))
      @parts_spec_path= File.join(@project_bundle, "project", "safari", "Parts", "setup.js")
      @datasources_spec_path= File.join(@project_bundle, "project", "Parts", "datasources.js")
      @css_path= File.join(@project_bundle, "project", "safari", "main.css")
      @markup_path= File.join(@project_bundle, "project", "index.html")
      @images_folder= File.join(@output_folder, "images")
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
    
    def doc
      return @doc if @doc
      
      html= File.read(@markup_path)
      @doc= Nokogiri::HTML(html)
    end

    def controller
      return @controller if @controller
      @controller= Controller.new(@name, @namespace)
    end
    
    def nib
      return @nib if @nib
      
      @nib= Nib::Nib.new(@name, controller)
      @nib.add_view_from_path(@parts_spec_path)
      @nib.add_datasources_from_path(@datasources_spec_path)
      @nib
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
      
      nib.views.each { |view|
        # Use a copy of the view's items, because the iterator isn't stable if
        # items are removed while iterating.
        items= view.items.clone
        items.each { |item|
          html= doc.css(item.name)[0]
          item.fixup_html(html)
        }
      }
    end
    
    def convert
      fixup_html
      
      FileUtils.mkdir_p(@output_folder)
      FileUtils.mkdir_p(@images_folder)
      
      Dir.chdir(@output_folder) do
        File.open("#{@name.capitalize}Controller.js", "w") { |controller_file|
          controller_file << controller.declaration
        }
        File.open("#{@name}.js", "w") { |nib_file|
          nib_file << nib.declaration
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
