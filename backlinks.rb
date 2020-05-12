# Backlink Builder

PATH_TO_NOTEPLAN = "/Users/ale/Library/Mobile Documents/iCloud~co~noteplan~NotePlan/Documents"
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

def title_from_note_file file
  filename = File.basename(file)
  # Is the title the first line, or the filename?
  # Turns out it's the first line, minus
end

all_note_files.each do |file|
  filename = File.basename(file)
  note_title = File.basename(filename)

  all_content = File.read(file)

  if links_from_text all_content
    puts "----"
    puts "# Links in page #{note_title}"
    puts
    # puts "Checking #{File.basename(file)} for links"
    lines_from_file(file).each do |line|
      links = links_from_text(line)
      # TODO: remove "- " and other crap from the beginning of the line,
      # *if* we want to use the line for anything (maybe we don't)
      # line = line.gsub("- ","")
      if links
        link = links[1]
        link_title = links[2]
        puts "- #{link}"
      end
    end
    puts "----"
  end
end
