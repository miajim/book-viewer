require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"

# get "/*" do |path|
#   # File.read "public/template.html"
#   path = path.split('/').filter_map { |x| x.capitalize unless x.empty? }.join(" ")
#   erb :home, :locals => { :title_from_path => "#{path}" }
# end

before do 
  @files = Dir.entries("data")
  @files.select! { |file| file =~ /^chp\d+\.txt$/ }

  @chapters = @files.map { |chapter| chapter.sub("chp", "Chapter ").sub(".txt", "")} 
  @chapters = @chapters.sort_by { |chapter| chapter.split(" ").last.to_i }

  @chapters.reverse! if params[:sort] == "desc"

  @contents = File.readlines("data/toc.txt")
end

not_found do 
  redirect "/"
end

# num_visits = 0
# alternatively:
# @chapters = files.map { |chapter| chapter.scan(/(chp)(\d+)/).map { |subarr| "Chapter #{subarr.last}" } }.flatten

get "/" do
  @title = "The Adventures of Sherlock Holmes"
  # if path == "sort" 
  #   @sort_path = true
  #   num_visits += 1
  #   @sort_asc = num_visits.odd? ? true : false
  # end

  erb :home
end

get "/chapters/:number" do
  num = params[:number].to_i

  not_found unless (1..@contents.size).cover?(num)

  chapter_name = @contents[num - 1]
  @title = "Chapter #{num}: #{chapter_name}"
  @chapter = File.readlines("data/chp#{num}.txt")

  erb :chapter
end

get "/show/:name" do 
  params[:name]
  # code = "<%= params[:name] %>"
  # erb code, layout: :none
end

# Algo for search
# create a hash of chapter numbers (keys) to chapter titles (values)
# select chapter titles (@contents) that include the search term
# iterate through the list of chapter titles 
# select & return the titles that include the search term (case insensitive)

get "/search" do
  if params[:query]
    query = params[:query]
    chp_nums = (1..@contents.size).to_a
    contents_hsh = chp_nums.zip(@contents).to_h

    @filtered_lines = {}
    @filtered_contents = contents_hsh.select do |chp_num, chp_title|
      chapter = File.readlines("data/chp#{chp_num}.txt")
      lines = {}
      in_paragraphs(chapter).each_with_index do |line, idx|
        lines[idx] = line if line.gsub!(query, "<strong>#{query}</strong>")
      end
      @filtered_lines[chp_title] = lines unless lines.empty?
    end
  end

  erb :search
end

# Algo for in_paragraphs
# input: one (long) string, @chapter
# split string at pairs of double quote (") --> array of strings
# iterate over the string elements in the resulting array
# surround each element in <p></p> tags

helpers do 
  def in_paragraphs(str_arr)
    result = []
    lines = []
    str_arr.each do |line|
      if line == "\n"
        result << lines.join(" ")
        lines = []
      else
        line.delete!("\n")
        lines << line
      end
    end
    result
  end
end