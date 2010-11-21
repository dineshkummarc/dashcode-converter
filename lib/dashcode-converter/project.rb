module DashcodeConverter

  CSS_IMAGE_URL_REGEX= /url\("?(.*\.(jpg|png|gif))"?\)/
  BUNDLE_EXTENSION= "jsnib"
  
  class Project
    
    attr_accessor :namespace, :name

    PROJECT_TEMPLATE= <<-EOF
      name: <%=name%>
      version: 1.0.0
      notice: src/NOTICE
      type: application
      export: <%=namespace%>
      output folder: build

      external:
        - name: coherent
          path: ext/coherent
          repository: https://github.com/jeffwatkins/coherent.git

      include:
        - coherent
  
      source:
        - src/index.html
        - src/<%=name%>.jsnib
    EOF
    
    def initialize(project_bundle, options)
      output_folder= options[:output_folder]
      
      @project_bundle= File.expand_path(project_bundle)
      @name= File.basename(@project_bundle, ".*")
      @namespace= options[:namespace] || @name
      @output_folder= File.expand_path(File.join(output_folder, @name))
      @nib_folder= "#{@name}.#{BUNDLE_EXTENSION}"
      @nib_output_folder= File.join(@output_folder, "src", @nib_folder)
      
      @images_output_folder= File.join(@output_folder, "src", @nib_folder, "images")
      
      @parts_spec_path= File.join(@project_bundle, "project", "safari", "Parts", "setup.js")
      @datasources_spec_path= File.join(@project_bundle, "project", "Parts", "datasources.js")
      @css_path= File.join(@project_bundle, "project", "safari", "main.css")
      @markup_path= File.join(@project_bundle, "project", "index.html")
      @scripts= Scripts.new(File.join(@project_bundle, "project", "safari"))
      
      @controller_name= "#{@name.capitalize}Controller"
      
      FileUtils.mkdir_p(@output_folder)
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
      path_relative_to_folder(path, @nib_output_folder)
    end
    
    def doc
      return @doc if @doc
      
      html= File.read(@markup_path)
      @doc= Nokogiri::HTML(html)
    end

    def controller
      return @controller if @controller
      @controller= Controller.new(@name, @namespace, @scripts)
    end
    
    def nib
      return @nib if @nib
      
      @nib= Nib::Nib.new(@name, controller)
      @nib.add_view_from_path(@parts_spec_path, "#{@name}-view", true)
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
          new_image_file= File.join(@images_output_folder, File.basename(image_file))
          FileUtils.mkdir_p(File.dirname(new_image_file))
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
        new_image_file= File.join(@images_output_folder, File.basename(image_file))
        FileUtils.mkdir_p(File.dirname(new_image_file))
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
      
      FileUtils.mkdir_p(@nib_output_folder)
      FileUtils.mkdir_p(@output_folder)
      FileUtils.mkdir_p(@images_output_folder)

      Dir.chdir(@output_folder) do
        File.open("#{@name}.jsproj", "w") { |project_file|
          project_file << ERB.new(PROJECT_TEMPLATE.remove_indent).result(binding)
        }
      end
      
      Dir.chdir(File.join(@output_folder, "src")) do
        File.open("index.html", "w") { |html|
          html <<%{
            <!DOCTYPE HTML>
            <html>
              <head>
                <link rel="stylesheet" href="#{@name}-debug.css" type="text/css" media="screen" charset="utf-8">
                <script src="#{@name}-debug.js" type="text/javascript" charset="utf-8"></script>
              </head>
  
              <body>
              </body>
              <script type="text/javascript" charset="utf-8">
                distil.onready(function(){
    
                  var controller= new #{namespace}.#{@controller_name}({
                                      nibName: '#{@name}'
                                    });
                  document.body.appendChild(controller.view().node);
      
                });
  
              </script>
            </html>
          }.remove_indent
        }
      end
      
      Dir.chdir(@nib_output_folder) do
        File.open("#{@controller_name}.js", "w") { |controller_file|
          controller_file << controller.declaration
        }
        File.open("#{@name}.js", "w") { |nib_file|
          nib_file << nib.declaration
        }
        File.open("#{@name}.css", "w") { |css_file|
          css_file << css
        }
        File.open("#{@name}-view.html", "w") { |html_file|
          html_file << "<div>" << doc.css("body > *:first-child")[0].serialize << "</div>"
        }
      end
      
      Dir.chdir(@output_folder) do
        system 'distil'
      end
      
    end
    
  end
  
end
