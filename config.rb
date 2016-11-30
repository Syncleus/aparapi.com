###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

# With alternative layout
# page "/path/to/file.html", layout: :otherlayout

# Proxy pages (http://middlemanapp.com/basics/dynamic-pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", locals: {
#  which_fake_page: "Rendering a fake page with a local variable" }

# General configuration
# Reload the browser automatically whenever files change
configure :development do
    activate :livereload
end

# Middleman-Sprockets - https://github.com/middleman/middleman-sprockets
activate :sprockets

# Middleman-Syntax - https://github.com/middleman/middleman-syntax
set :haml, {:ugly => false, :format => :html5}
set :markdown_engine, :redcarpet
set :markdown, fenced_code_blocks: true, smartypants: true, footnotes: true,
    link_attributes: {rel: 'nofollow'}, tables: true
activate :syntax

activate :navtree do |options|
    options.automatic_tree_updates = false
    options.promote_files = ['index.html.haml']
end

###
# Helpers
###

# Methods defined in the helpers block are available in templates
helpers do
    
    def navigation(value, depth = Float::INFINITY, key = nil, level = 0)
        html = ''
        
        if value.is_a?(String)
            # This is a file.
            # Get the Sitemap resource for this file.
            # note: sitemap.extensionless_path converts the path to its 'post-build' extension.
            
            # Make sure the extension path ends with .html (in case we're parsing someting like .adoc)
            extensionlessPath = sitemap.extensionless_path(value)
            unless extensionlessPath.end_with? ".html"
                extensionlessPath << ".html"
            end
            
            this_resource = sitemap.find_resource_by_path(extensionlessPath)
            if this_resource
                # Define string for active states.
                active = this_resource == current_page ? 'active' : ''
                title = discover_title(this_resource)
                link = link_to(title, this_resource)
                html << "<li class='no-padding'>"
                html << "<ul class='collapsible collapsible-accordion'>"
                html << "<li class='bold'>"
                html << "#{link}"
                html << "</li></ul></li>"
                # html << "<li class='child #{active}'>#{link}</li>"
            end
        else
            # This is the first level source directory. We treat it special because
            # it has no key and needs no list item.
            if key.nil?
                value.each do |newkey, child|
                    html << navigation(child, depth, newkey, level + 1)
                end
                # Continue rendering deeper levels of the tree, unless restricted by depth.
            elsif depth >= (level + 1)
                # This is a directory.
                # The directory has a key and should be listed in the page hieararcy with HTML.
                dir_name = format_directory_name(key)
                html << "<li class='no-padding'>"
                html << "<ul class='collapsible collapsible-accordion'>"
                html << "<li class='bold'>"
                html << "<a class='collapsible-header waves-effect waves-teal'>"
                html << "#{dir_name}"
                html << "</a>"
                html << "<div class='collapsible-body'>"
                html << "<ul>"
                
                # Loop through all the directory's contents.
                value.each do |newkey, child|
                    html << navigation(child, depth, newkey, level + 1)
                end
                html << "</ul></div></li></ul></li>"
            end
        end
        return html
    end
    
    def page_title
        if current_page.data.header_title.present?
            current_page.data.header_title
        elsif current_page.data.title.present?
            current_page.data.title
        end
    end

    def page_description
        if current_page.data.description.present?
            current_page.data.description
        end
    end
end

# Add bower's directory to sprockets asset path
after_configuration do
    @bower_config = JSON.parse(IO.read("#{root}/.bowerrc"))
    sprockets.append_path File.join "#{root}", @bower_config["directory"]
end

# Build-specific configuration
configure :build do
    
    # Minify CSS on build
    # activate :minify_css
    
    # Minify Javascript on build
    # activate :minify_javascript
    
    # Use relative URLs
    # activate :relative_assets
    # set :relative_links, true
    
    # Ignoring Files
    ignore '/template.html'
end
