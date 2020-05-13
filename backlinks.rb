BACKLINKS_MARKER = "♻︎ Backlinks"

PATH_TO_NOTEPLAN = "#{ENV['HOME']}/Library/Mobile Documents/iCloud~co~noteplan~NotePlan/Documents"
PATH_TO_NOTES = "#{PATH_TO_NOTEPLAN}/Notes"
PATH_TO_CALENDAR = "#{PATH_TO_NOTEPLAN}/Calendar"

REGEX_LINK = /(\[\[[^\]]+\]\])/
REGEX_BACKLINKS = /\n\n#{BACKLINKS_MARKER}\n(.+\n)+#{BACKLINKS_MARKER}/

def all_note_files
  Dir.glob("#{PATH_TO_NOTES}/**/*.{txt,md}").sort
end

def file_contents file
  File.read(file)
end

def title_from_note_file file
  first_line = File.readlines(file).first || ""
  title = first_line.gsub("# ","").strip
  return title
end

def has_links file
  REGEX_LINK.match?(File.read(file))
end

def links_from_file file
  contents = file_contents(file)
  # obviously, we need to ignore the Backlinks block
  contents.gsub!(REGEX_BACKLINKS,"")

  file_links = []
  contents.split("\n").each do |line|
    if REGEX_LINK.match?(line)
      links = line.scan(REGEX_LINK).flatten
      links.each do |link|
        file_links.push(link)
      end
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
    contents.gsub!(REGEX_BACKLINKS, backlink_block)
  else
    contents << backlink_block
  end

  File.open(file, 'w') do |f|
    f << contents.strip
  end

end

link_database = []

all_note_files.each do |file|
  # 1. Build a database of all links in all pages
  note_title = title_from_note_file(file)

  next if note_title.empty?

  if has_links(file)
    links = links_from_file(file)
    links.each do |link|
      link_database.push({
        :from => "[[#{note_title}]]",
        :to => link
      })
    end
  end

end

all_note_files.each do |file|
  # 2. For each page, check the database for links that point at that page
  note_title = title_from_note_file(file)

  next if note_title.empty?

  links_to_page = link_database.select { |link|
    link[:to].downcase == "[[#{note_title}]]".downcase
  }.map { |link|
    link[:from]
  }.uniq

  # 3. Bake backlinks in note file, replacing existing Backlinks (otherwise you end up with repeated backlinks)
  if links_to_page.length > 0
    update_backlinks_block(file, links_to_page)
  end

end
