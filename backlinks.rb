start = Time.now
BACKLINKS_MARKER = "♻︎ Backlinks"

PATH_TO_NOTEPLAN = "#{ENV['HOME']}/Library/Mobile Documents/iCloud~co~noteplan~NotePlan/Documents"
PATH_TO_NOTES = "#{PATH_TO_NOTEPLAN}/Notes"
PATH_TO_CALENDAR = "#{PATH_TO_NOTEPLAN}/Calendar"

REGEX_LINK = /(\[\[[^\]]+\]\])/
REGEX_BACKLINKS = /\n\n#{BACKLINKS_MARKER}\n(.+\n)+#{BACKLINKS_MARKER}/

def all_note_files
  notes = Dir.glob("#{PATH_TO_NOTES}/**/*.{txt,md}")
  calendar = Dir.glob("#{PATH_TO_CALENDAR}/**/*.{txt,md}")
  return notes + calendar
end

def file_contents file
  File.read(file).strip
end

def is_calendar file
  File.dirname(file).match?("Calendar")
end

def title_from_note_file file
  if is_calendar(file)
    date = File.basename(file,'.*')
    year = date[0..3]
    month = date[4..5]
    day = date[6..7]
    return "#{year}-#{month}-#{day}"
  else
    first_line = File.readlines(file).first || ""
    return first_line.gsub(/#+/,"").strip
  end
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

def get_link_database
  link_database = []
  all_note_files.each do |file|
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
  return link_database
end

def links_to_page title, link_database
  links_to_page = link_database.select { |link|
    link[:to].downcase == "[[#{title}]]".downcase
  }.map { |link|
    link[:from]
  }.uniq
  return links_to_page
end

link_database = get_link_database()

all_note_files.each do |file|
  note_title = title_from_note_file(file)
  next if note_title.empty?
  links_to_page = links_to_page(note_title, link_database)
  if links_to_page.length > 0
    update_backlinks_block(file, links_to_page)
  end
end

puts "Updated backlinks for #{all_note_files.size} notes in #{Time.now - start} seconds"