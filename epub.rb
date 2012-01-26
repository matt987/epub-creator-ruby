#https://github.com/banux/ruby-epub/blob/master/lib/ruby-epub.rb

require 'zip/zip'
require 'nokogiri'

class Epub

   def initialize(filename)
     begin
      @zip = Zip::ZipFile.open(filename)
      @opf = opf
      @metadata = metadata
      @cover_image = cover_image
      @xhtmls = xhtmls
     rescue
       raise "File not fund"
     end
   end

   def opf
      container_file = @zip.get_input_stream("META-INF/container.xml")
      container = Nokogiri::XML container_file
      opf_path = container.at_css("rootfiles rootfile")['full-path']
      tab_path = opf_path.split('/')
      @base_path = tab_path.size > 1 ? tab_path[0] + '/' : ''
      opf_file = @zip.get_input_stream(opf_path)
      opf = Nokogiri::XML opf_file
      opf.remove_namespaces!
   end

   def metadata
    meta = {title: '', language: '', publisher: '', date: '', rights: '', creator: ''}
    meta.each do |key, value|
      opf_at_css = @opf.at_css(key.to_s)
      meta[key] = opf_at_css.content if opf_at_css 
    end
   end
 
   def cover_image
     cover_by_id || cover_by_meta || cover_by_html
   end

   def cover_by_html
    cover_item = @opf.at_css("package guide reference[@type='cover']")
    if cover_item
      cover_url = cover_item['href']
      doc_cover = Nokogiri::HTML @zip.get_input_stream(@base_path + cover_url)
      tab_path = cover_url.split('/')
      html_path = ''
      if tab_path.size > 1
         html_path = tab_path[0] + '/'
      end
      img_src = doc_cover.xpath('//img').first
      begin
       @image_cover = @zip.get_input_stream(@base_path + html_path + img_src['src']) {|f| f.read}
      rescue
       nil
      end
    end
   end

   def cover_by_meta
    img_id = @opf.at_css("meta[@name='cover']")
    if img_id
    img_item = @opf.at_css("manifest item[id='"+ img_id['content'] + "']")
    begin
      img_url = @base_path + img_item['href']
      @image_cover = @zip.get_input_stream(img_url) {|f| f.read}
    rescue
      nil
    end
    end
   end

   def cover_by_id
    img_item = @opf.at_css("manifest item #cover")
    begin
      img_url = img_item['href']
      puts img_url
      @image_cover = @zip.get_input_stream(img_url) {|f| f.read}
    rescue
      nil
    end
   end
   
   def xhtmls
     files_urls = []
     @opf.at_css("package manifest").children.each do |i| 
       if i['media-type'] == "application/xhtml+xml" 
	 files_urls << @base_path + i['href'].to_s
       end
     end
     files_urls
   end
   
   def get_xhtml_file(path)
     puts path
     @zip.get_input_stream(path) {|f| f.read}
   end
   

end