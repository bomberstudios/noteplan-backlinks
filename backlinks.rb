# Backlink Builder

PATH_TO_NOTEPLAN = "."
# PATH_TO_NOTEPLAN = "/Users/ale/Library/Mobile Documents/iCloud~co~noteplan~NotePlan/Documents"
PATH_TO_NOTES = "#{PATH_TO_NOTEPLAN}/Notes"
PATH_TO_CALENDAR = "#{PATH_TO_NOTEPLAN}/Calendar"

def all_note_files
  Dir.glob("#{PATH_TO_NOTES}/**.{txt,md}").sort
end

def lines_from_file file
  File.readlines(file)
end

def links_from_text text
  regex = /(\[\[([^\]]+)\]\])/
  regex.match(text)
end

def file_contents file
  File.read(file)
end

def title_from_note_file file
  first_line = lines_from_file(file).first
  title = first_line.gsub("# ","").strip
  return title
  # Is the title the first line, or the filename?
  # Turns out it's the first line, minus the header cruft
end

def has_links file
  if links_from_text(File.read(file))
    return true
  else
    return false
  end
end

def links_from_file file
  file_links = []
  lines_from_file(file).each do |line|
    links = links_from_text(line)
    if links
      file_links.push(links)
    end
  end
  return file_links
end

def update_backlinks_block(file, links)
  backlink_block_regex = /\n\n♻︎ Backlinks\n(.+\n)+♻︎ Backlinks/

  backlink_block = "\n\n♻︎ Backlinks\n"
  links.sort.each do |link|
    backlink_block << "- #{link}\n"
  end
  backlink_block << "♻︎ Backlinks\n"

  contents = file_contents(file)

  if contents.match(backlink_block_regex)
    puts "File already has a backlinks block, updating"
    contents.gsub(backlink_block_regex, backlink_block)
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
    links = links_from_file(file)
    links.each do |link|
      link_full = link[1]
      link_title = link[2]
      if !link_database[note_title]
        link_database[note_title] = []
      end
      link_database[note_title].push(link_full)
    end
  end
  # 2. For each page, check the database for links that point at that page
  links_to_page = link_database[note_title]
  if links_to_page
    puts note_title
    # 3. Bake backlinks in note file, replacing existing Backlinks (otherwise you end up with repeated backlinks)
    update_backlinks_block(file, links_to_page)
  end
end

# puts link_database

