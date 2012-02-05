use strict;
use warnings;
use File::Find;
use Getopt::Long;
use PPI;
use Text::Diff;
use Text::Diff::HTML;

my $plugin_dir;
my $new_codebase_dir;
my $old_codebase_dir;
my $plugin_label = 'Plugin';
my $new_label = 'New Codebase';
my $old_label = 'Old Codebase';
my $output_file = './report.html';

GetOptions (
  "plugin_dir=s"       => \$plugin_dir,
  "new_codebase_dir=s" => \$new_codebase_dir,
  "old_codebase_dir=s" => \$old_codebase_dir,
  "plugin_label=s"     => \$plugin_label,
  "new_label=s"        => \$new_label,
  "old_label=s"        => \$old_label,
  "output_file=s"      => \$output_file,
);

die "missing options" unless $plugin_dir and $new_codebase_dir and $old_codebase_dir;

my @lib_dirs = qw(
  ensembl-external/modules
  ensembl-functgenomics/modules
  ensembl-variation/modules
  ensembl-draw/modules
  ensembl-compara/modules
  ensembl/modules
  modules
);

print "Scanning lib dirs...\n";

my $plugin_mods = find_modules("$plugin_dir/modules");
my $new_mods = find_modules(map {"$new_codebase_dir/$_"} @lib_dirs);
my $old_mods = find_modules(map {"$old_codebase_dir/$_"} @lib_dirs);

print "Comparing modules...\n";

my $mods = {
  changed => {},
  removed => [],
  unique  => [],
};

foreach my $mod (sort keys %$plugin_mods) {
  if (!exists $new_mods->{$mod}) {
    if (!exists $old_mods->{$mod}) {
      push @{$mods->{unique}}, $mod;
    } else {
      push @{$mods->{removed}}, $mod;      
    }
    next;
  } 
  
  next unless exists $old_mods->{$mod};
  
  # compare subs
  
  my $plugin_subs = parse_subs($plugin_mods->{$mod}->{file});
  my $new_subs = parse_subs($new_mods->{$mod}->{file});
  my $old_subs = parse_subs($old_mods->{$mod}->{file});
    
  my $subs = {
    changed => {},
    removed => [],
    unique  => [],
  };
  
  my $differences = 0;
  
  foreach my $sub (keys %$plugin_subs) {
    if (!exists $new_subs->{$sub}) {
      if (!exists $old_subs->{$sub}) {
        #push @{$subs->{unique}}, $sub;     # not interested in unique subs (for now)
        #$differences ++;                 
      } else {
        push @{$subs->{removed}}, $sub;
        $differences ++;
      }
      next;
    }  
    
    my ($a, $b, $c) = ($old_subs->{$sub}, $new_subs->{$sub}, $plugin_subs->{$sub});
    if ($a->{content} ne $b->{content}) {
      my $diff1 = diff \$a->{content}, \$b->{content}, {
        STYLE => 'Text::Diff::HTML', 
        FILENAME_A => $old_label, 
        OFFSET_A => $a->{line_number},
        FILENAME_B => $new_label, 
        OFFSET_B => $b->{line_number},
      };
      
#      my $diff2 = diff \$a->{content}, \$c->{content}, {
#        STYLE => 'Text::Diff::HTML', 
#        FILENAME_A => $old_label, 
#        OFFSET_A => $a->{line_number},
#        FILENAME_B => $plugin_label, 
#        OFFSET_B => $c->{line_number},
#      };
      
      my $diff3 = diff \$c->{content}, \$b->{content}, {
        STYLE => 'Text::Diff::HTML', 
        FILENAME_A => $plugin_label, 
        OFFSET_A => $c->{line_number},
        FILENAME_B => $new_label, 
        OFFSET_B => $b->{line_number},
      };
      
      $subs->{changed}->{$sub} = {
        diff_1 => $diff1,
#        diff_2 => $diff2,
        diff_3 => $diff3,
      };
      $differences ++;
    }
    
    
  }
  
  if ($differences) {
    $mods->{changed}->{$mod} = $subs;
  }
  
}

print "Creating report ($output_file)...\n";
open my $fh, '>', $output_file;
print $fh render_report();
close $fh;


sub render_report {
  my $html;
  
  my $title = "'$plugin_label' Module Audit";
  my $stamp = `date`;
  
  if (my @m = @{$mods->{removed}}) {
    $html .= qq{<hr /><h3>Removed Modules</h3>};
    $html .= qq{<p>Modules in <span class="plugin">$plugin_label</span> which were present in <span class="old">$old_label</span> but have been removed in <s
pan class="new">$new_label</span></p>};
    $html .= qq{<ul>\n} . join( "\n", map {'<li>' . _render_mod($_) . '</li>'} @m ) . qq{</ul>\n};
  }
  
  if (my %m = %{$mods->{changed}}) {
    $html .= qq{<hr /><h3>Changed Modules</h3>};
    $html .= qq{<p>Modules in <span class="plugin">$plugin_label</span> containing subs that changed between <span class="old">$old_label</span> and <span cl
ass="new">$new_label</span></h3>\n};
    $html .= qq{<ul>\n} . join( "\n", map {qq{<li>} . _render_mod_detail($_, $m{$_}) . qq{</li>\n}} sort keys %m ) . qq{</ul>\n};
  }
    
  if (my @m = @{$mods->{unique}}) {
    $html .= qq{<hr /><h3>Unique Modules</h3>};
    $html .= qq{<p>Modules in <span class="plugin">$plugin_label</span> that do not exist in <span class="old">$old_label</span> or <span class="new">$new_la
bel</span></p>\n};
    $html .= qq{<ul>\n} . join( "\n", map {'<li>' . _render_mod($_) . '</li>'} @m ) . qq{</ul>\n};
  }
  
  $html = qq{
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="eng">
      <head>
        <title>$title</title>
        <style>
          body {
            font-family: Luxi Sans, Helvetica, Arial, Geneva, sans-serif;
            font-size: 14px;
            margin: 20px;
          }
          pre {
            padding: 10px;
            border: #999999 1px solid;
            background-color: #f0f0f0;
          }
          span.plugin {font-weight: bold;}
          span.new {font-weight: bold;}
          span.old {font-weight: bold;}
          span.module {}
          span.sub {font-family:monospace}
          span.removed {color: red}  
          ul.subs {margin-bottom:8px}  
          .stamp {font-size: 12px; font-style:italic} 
          
          .diff { margin-top: 8px; white-space: pre; padding: 10px; border:#999999 1px solid; font-family:monospace}
          .file span { display: block; }
          .file .fileheader, .file .hunkheader {color: #888; }
          .file .hunk .ctx { background: #eee;}
          .file .hunk ins { background: #dfd; text-decoration: none; display: block; }
          .file .hunk del { background: #fdd; text-decoration: none; display: block; }   
          
          .file .fileheader {
              background-color: #999999;
              color: white;
              font-weight: bold;
              margin-bottom: 5px;
              padding: 5px;
          }
        </style>
        <script>
          function toggle(id) {
            var ele = document.getElementById(id);
            ele.style.display = ele.style.display == 'none' ? 'block' : 'none';
          }
        </script>
      </head>
      <body>
        <h1>$title</h1>
        <p class="paths">
          <b>$plugin_label</b> - $plugin_dir<br />
          <b>$new_label</b> - $new_codebase_dir<br />
          <b>$old_label</b> - $old_codebase_dir<br />
        </p>
        $html
        <hr />
        <p class="stamp">Generated $stamp</p>
      </body>
    </html>  
  };
   
  return $html;
}

sub _render_mod {
  my $mod = shift;
  return qq{<span class="module" title="$plugin_mods->{$mod}->{relative_file}">$plugin_mods->{$mod}->{relative_file}</span>};
}

sub _render_mod_detail {
  my ($mod, $subs) = @_;
  my $html;
  
  if (my @s = @{$subs->{removed}}) {
    $html .= join( "\n", map {qq{<li><span class="sub removed">sub $_ [REMOVED]</span></li>}} @s );
  }
  
  if (my %s = %{$subs->{changed}}) {
    $html .= join( "\n", map {qq{
      <li>
        <span class="sub"><a title="Click to view diff output" href="#" onclick="toggle('diff_${mod}_$_');return false;">sub $_</a></span>
        <div class="diff" id="diff_${mod}_$_" style="display:none">$s{$_}->{diff_1}
          $s{$_}->{diff_3}
        </div>
      </li>\n}} sort keys %s );
  }
    
  $html = _render_mod($mod) . qq{\n<ul class="subs">$html</ul>};
  
  return $html;
}

sub find_modules {
  my @dirs = @_;
  my $found;
  
  my $wanted = sub {
    if (/\.pm$/) {
      my $dir  = $File::Find::topdir;
      my $file = $File::Find::name;
      
      (my $relative_file = $file) =~ s/^$dir\///;    
      (my $package = $relative_file) =~ s/\//::/g;
      $package =~ s/\.pm$//g;
      
      $found->{$package} = {
        dir => $dir,
        file => $file,
        relative_file => $relative_file,
      };
    }
  };

  find($wanted, @dirs);
  
  return $found;
}

sub parse_subs {
  my $file = shift;
  my %subs; 
  my $document = PPI::Document->new($file) or die "PPI could not open file '$file': $@";
  $document->index_locations;
  for my $sub ( @{ $document->find('PPI::Statement::Sub') || [] } ) {
      unless ( $sub->forward ) {
          $subs{ $sub->name } = {
            content => $sub->content, 
            line_number => $sub->line_number
          };
      }
  }
  return \%subs;
}
