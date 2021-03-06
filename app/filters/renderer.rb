class Renderer
  class << self
    def filters(format)
      [
        AutolinkFilter,
        if format == "markdown"
          MarkdownFilter
        else
          [
            MarkdownCodeFilter,
            SimpleFilter,
            UnserializeFilter
          ]
        end,
        CodeFilter,
        ImageFilter,
        LinkFilter,
        SanitizeFilter
      ].flatten
    end

    def render(post, options={})
      options[:format] ||= "markdown"
      filters(options[:format]).inject(post) { |str, filter| filter.new(str).to_html }.html_safe
    end
  end
end
