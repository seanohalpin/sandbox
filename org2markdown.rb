#!/usr/bin/env ruby
# getting to the point where I'll need to build a DOM

$confluence = ARGV.delete("--confluence")
$APP_DEBUG = ARGV.delete("--debug")

def slide
  puts "\n!SLIDE\n"
end

def output_code_line(line)
  puts (" " * 4) + line.chomp
end

def code_block(lines)
  lines.each_line do |line|
    output_code_line(line)
  end
end

def code_span(line)
  "`#{line.chomp}`"
end


def start_code_block
  puts
end

def end_code_block
  puts
end

def expand_link(link)
  # http://en.wikipedia.com/wiki/
  scheme, rest = link.split(/:/)
  case link
  when /wp:/
    scheme = "http://en.wikipedia.com/wiki/"
  when /[a-z+]:/
    scheme = scheme + ":"
  end
  dbg [:scheme, scheme, :rest, rest].inspect
  scheme + rest.to_s
end

def dbg(*a)
  STDERR.puts "DEBUG: " + a.inspect if $APP_DEBUG
end

in_quote = false
in_code = false
spaces = 0

ARGF.each_line do |line|
  line = line.chomp
  dbg :input, line
  case line
  when /^\s*<.*>\s*$/i
    # date
    dbg :case, 1, :angle_date
    next
  when /^\s*:\s*(.*)/i
    # code line
    dbg :case, 2, :code_line, $1
    code_block($1)
    next
  when /^\s*(\$.*)/i
    # command line
    dbg :case, 2, :code_line, $1
    code_block($1)
    next
  when /^\s*#\+BEGIN_QUOTE/i
    # start quote
    dbg :case, 3, :begin_quote
    in_quote = true
    next
  when /^\s*#\+END_QUOTE/i
    # end quote
    dbg :case, 4, :end_quote
    in_quote = false
    next
  when /^\s*#\+BEGIN_SRC/i
    # start code block
    dbg :case, 5, :begin_src
    in_code = 0
    spaces = 0
    #dbg :BEGIN_SRC
    start_code_block
    next
  when /^\s*#\+END_SRC/i
    # end code block
    dbg :case, 6, :end_src
    in_code = false
    spaces = 0
    #dbg :END_SRC
    end_code_block
    next

    # github wiki Gollum-style code blocks
  when /^```[a-zA-Z]+/i
    # start code block
    dbg :case, 5, :begin_src
    in_code = 0
    spaces = 0
    #dbg :BEGIN_SRC
    start_code_block
    next
  when /^```\s*$/i
    # end code block
    dbg :case, 6, :end_src
    in_code = false
    spaces = 0
    #dbg :END_SRC
    end_code_block
    next

  when /^\s*#/i
    # comment
    dbg :case, 7, :comment
    #dbg :IGNORE
    # ignore
    next
  when /^\*+ !SLIDE/
    # SLIDES
    dbg :case, 8, :slide
    #dbg :SLIDE
    slide
    next
  when /^\*+/
    # headings
    dbg :case, 9, :heading
    line = line.gsub(/^(\*+)(\s+.*$)/) do |m|
      "\n#{"#" * $1.size} #{$2}\n"
    end
  when /^\|\-+/
    dbg :case, 10, :table_header
    # skip table header lines
    next
  when /^\s*\-+\s+/
    # bullet list - passthrough as same in org and markdown
    dbg :case, 11, :bullet_list_item
  end

  # replace links

  line = line.gsub(/\[\[(.*?)\]\]/){|match|
    link, desc = $1.split(/\]\[/)
    dbg [:match, match, :one, $1, :link, link, :desc, desc].inspect
    link = expand_link(link)
    if desc
      "[#{desc}](#{link})"
    else
      "[#{link}](#{link})"
    end
  }

  # formatting

  # italic
  line = line.gsub(/\s\/(.+?)\/\B/){|match|
    # make sure not inside link
    " _#{$1}_ "
  }

  # bold
  line = line.gsub(/\B\*(.+?)\*\B/){|match|
    # make sure not inside link
    " **#{$1}** "
  }

  # bit crude but works (mostly)
  # code span
  line = line.gsub(/\s=(.*?)=/, ' `\\1`')

  # handle code block
  if in_code
    dbg :case, :in_code
    if in_code == 0
      m = line.match(/^\s+/)
      spaces = m.to_s.size
    end
    # p [:line, line, :spaces, spaces]
    output_code_line line
    in_code += 1
  else
    if in_quote
      dbg :case, :in_quote
      # print "bq. "
    end
    dbg :output, line
    puts line
  end

end
