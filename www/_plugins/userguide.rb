require 'redcarpet'

module Jekyll
  class UserGuideFor < Liquid::For
    def render(context)
      sort_by = @attributes['sort_by']
      category = @attributes['category']

      sorted_collection = context[@collection_name].dup
      sorted_collection = sorted_collection.sort_by { |i| (i && i.to_liquid[@attributes['sort_by']]) || 0 }

      parts = context['page']['path'].split('/')
      page_dir = parts[0..parts.length-2].join('/')

      new_collection = []
      sorted_collection.each do |item|
        next if item.data['hidden']
        if dir_matches?(page_dir, item.path) # Make sure it's in the same directory
          if category.nil?
            new_collection.push(item)
          else
            if item.data['category'] == category  # Match the category
              new_collection.push(item)
            end
          end
        end
      end

      sorted_collection_name = "#{@collection_name}_sorted".sub('.', '_')
      context[sorted_collection_name] = new_collection
      @collection_name = sorted_collection_name

      super
    end

    def dir_matches?(page_dir, item_path)
      parts = item_path.split('/')
      item_dir = parts[0..parts.length-2].join('/')
      return page_dir == item_dir
    end

    def end_tag
      'enduserguide_for'
    end
  end

  module Converters
    module APILink
      @@NamespacePattern = /noda-ns:\/\/([A-Za-z0-9_.]*)/
      @@TypePattern      = /noda-type:\/\/([A-Za-z0-9_.]*)/
      @@MethodPattern      = /noda-method:\/\/([A-Za-z0-9_.]*)/
      @@FieldPattern      = /noda-field:\/\/([A-Za-z0-9_.]*)/
      @@PropertyPattern      = /noda-property:\/\/([A-Za-z0-9_.]*)/
      @@IssueUrlPattern  = /(\[[^\]]*\])\[issue (\d+)\]/
      @@IssueLinkPattern = /\[issue (\d+)\]\[\]/
      @@ApiUrlPrefix     = "../api/html/"

      def preprocess(text)
        text.gsub!(@@NamespacePattern) { |match| translateurl(match, 'N') }
        text.gsub!(@@TypePattern) { |match| translateurl(match, 'T') }
        text.gsub!(@@MethodPattern) { |match| translateurl(match, 'M') }
        text.gsub!(@@FieldPattern) { |match| translateurl(match, 'F') }
        text.gsub!(@@PropertyPattern) { |match| translateurl(match, 'P') }
        text.gsub!(@@IssueUrlPattern, '\1(https://github.com/nodatime/nodatime/issues/\2)')
        text.gsub!(@@IssueLinkPattern, '[issue \1](https://github.com/nodatime/nodatime/issues/\1)')
        text
      end

      def translateurl(match, prefix)
        match.gsub! /([A-Za-z0-9_.-]*):\/\//, ''
        match.gsub! /\./, '_'
        "#{@@ApiUrlPrefix}#{prefix}_#{match}.htm"
      end
    end

    class Markdown
      class NodaTimeMarkdownParser < RedcarpetParser
        def initialize(config)
          super

          # Patch @renderer to apply our transformations first.
          @renderer = Class.new(@renderer) do
            include APILink
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('userguide_for', Jekyll::UserGuideFor)
