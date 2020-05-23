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

def clean_line line
  # TODO: remove `@done()`, etc
  # TODO: Use a Regex, FFS
  return line
    .gsub('- [ ] ','')
    .gsub('- [x] ','')
    .gsub('- [-] ','')
    .gsub('- [>] ','')
    .gsub('* [ ] ','')
    .gsub('* [x] ','')
    .gsub('* [-] ','')
    .gsub('* [>] ','')
    .gsub('- ','')
    .gsub('* ','')
    .gsub('#### ','')
    .gsub('### ','')
    .gsub('## ','')
    .gsub('# ','')
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
        file_links.push({
          :to => link,
          :line => line
        })
      end
    end
  end
  return file_links
end

def update_backlinks_block(file, links)
  mtime = File.mtime(file)
  atime = File.atime(file)

  backlink_block = "\n\n#{BACKLINKS_MARKER}\n"
  links.sort_by { |link| link[:from].downcase }.each do |link|
    backlink_block << "- #{link[:from]}"
    if link[:from] != link[:line]
      backlink_block << ": #{clean_line(link[:line])}"
    end
    backlink_block << "\n"
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
  # Restore modification date so NotePlan does not change the note order
  File.utime(atime, mtime, file)
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
          :to => link[:to],
          :line => link[:line]
        })
      end
    end
  end
  return link_database
end

def links_to_page title, link_database
  links_to_page = link_database.select { |link|
    link[:to].downcase == "[[#{title}]]".downcase
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