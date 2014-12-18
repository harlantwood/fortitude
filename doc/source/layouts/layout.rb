class Views::Layout < Views::Shared::Base
  def content
    doctype!

    html {
      head {
        meta :charset => 'utf-8'
        meta :content => "IE=edge,chrome=1", :'http-equiv' => "X-UA-Compatible"
        meta :name => 'viewport', :content => 'width=device-width, initial-scale=1'

        comment "HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries"
        comment "WARNING: Respond.js doesn't work if you view the page via file://"
        comment %{[if lt IE 9]>
  <script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
  <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
<![endif]}

        stylesheet_link_tag 'all'
        javascript_include_tag 'all'

        render_title
      }

      body(:class => page_classes) {
        rawtext(yield)

        footer_javascript
      }
    }
  end

  def render_title
    title(current_page.data.title || "The Middleman")
  end

  def footer_javascript
    script :src => 'https://ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js'
    script :src => '/javascripts/bootstrap.js'
  end
end