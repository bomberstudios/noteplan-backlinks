# NotePlan Backlinks

This script automates the creation of backlinks between NotePlan notes.

Currently it only supports Notes, but I will implement backlinks for Calendar entries soon (because I need them, basically).

Disclaimer: I take absolutely no responsibility for any data loss. I assume you have backups, and know that running random code from the internet against your valuable data is generally considered a bad idea. Having said that, I use this with my own data and it _seems_ to work 🤞

## Usage

- Download the `backlinks.rb` file somewhere to your disk
- Open a Terminal, and run `ruby backlinks.rb`

Alternatively, you can create an AppleScript file with this content (adjusting the path to your `ruby` binary and to your `backlinks.rb` file):

```applescript
tell application "NotePlan"
	do shell script "LC_CTYPE='en_US.UTF-8' ruby /path/to/backlinks.rb"
end tell
```

Save that in `~/Library/Scripts/` and enable the Scripts Menu in Script Editor › Preferences › General. You’ll now have something like this on your main menu, and updating the backlinks will only take you two clicks:

![](docs/main-menu.png)

## Customization

By default, backlinks will be added at the end of your notes, with this format:

```
♻︎ Backlinks
- [[Link One]]
- [[Link Two]]
- [[Link Three]]
♻︎ Backlinks
```

To change it, edit the `BACKLINKS_MARKER` constant in the first line of `backlinks.rb`

The script assumes your Notes are synced using iCloud. If you're using Dropbox, you'll want to adjust the path in `PATH_TO_NOTEPLAN`.

## Roadmap

- [ ] Support Calendar notes
- [ ] Option to remove backlinks from all notes
- [ ] Read Backlinks template from a NotePlan note (this was something VoodooPad did, and I think it's brilliant)

