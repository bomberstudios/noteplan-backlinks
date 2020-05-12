# Backlink Builder

BACKLINKS_MARKER = "♻︎ Backlinks"
PATH_TO_NOTEPLAN = "."
# PATH_TO_NOTEPLAN = "/Users/ale/Library/Mobile Documents/iCloud~co~noteplan~NotePlan/Documents"
PATH_TO_NOTES = "#{PATH_TO_NOTEPLAN}/Notes"
PATH_TO_CALENDAR = "#{PATH_TO_NOTEPLAN}/Calendar"

REGEX_LINK = /(\[\[([^\]]+)\]\])/
# REGEX_LINK = Regexp.new(/(\[\[([^\]]+)\]\])/, Regexp::MULTILINE)
REGEX_BACKLINKS = /\n\n#{BACKLINKS_MARKER}\n(.+\n)+#{BACKLINKS_MARKER}/

def all_note_files
  Dir.glob("#{PATH_TO_NOTES}/**.{txt,md}").sort
end

def lines_from_file file
  File.readlines(file)
end

def links_from_text text
  REGEX_LINK.match(text)
end

def file_contents file
  File.read(file)
end

def title_from_note_file file
  first_line = lines_from_file(file).first
  title = first_line.gsub("# ","").strip
  return title
end

def has_links file
  REGEX_LINK.match?(File.read(file))
end

def links_from_file file
  contents = file_contents(file)
  # obviously, we need to ignore the Backlinks block!
  contents.gsub!(REGEX_BACKLINKS,"")

  file_links = []
  contents.split("\n").each do |line|
    links = REGEX_LINK.match(line)
    if links
      file_links.push(links[1])
    end
  end
  return file_links

end

def update_backlinks_block(file, links)
  backlink_block = "\n\n#{BACKLINKS_MARKER}\n"
  links.sort.each do |link|
    backlink_block << "- #{link}\n"
  end
  backlink_block << "#{BACKLINKS_MARKER}\n"

  contents = file_contents(file)

  if contents.match(REGEX_BACKLINKS)
    puts "File already has a backlinks block, updating"
    contents.gsub(REGEX_BACKLINKS, backlink_block)
  else
    puts "File has no backlinks block, creating"
    contents << backlink_block
  end

  File.open(file, 'w') do |f|
    f << contents
  end

end

link_database = Hash.new()

all_note_files.each do |file|
  # 1. Build a database of all links in all pages
  note_title = title_from_note_file(file)

  if has_links(file)
    puts "Finding links in #{note_title}"
    links = links_from_file(file)
    links.each do |link|
      if !link_database[note_title]
        link_database[note_title] = []
      end
      link_database[note_title].push(link)
    end
  end
  # 2. For each page, check the database for links that point at that page
  links_to_page = link_database[note_title]
  if links_to_page
    # 3. Bake backlinks in note file, replacing existing Backlinks (otherwise you end up with repeated backlinks)
    update_backlinks_block(file, links_to_page)
  end
end
