
push (@::gMatchers,
  {
   id =>        "errorDesc",
   pattern =>          q{errorDescr="(.+)"},
   action =>           q{
    
              my $description = ((defined $::gProperties{"summary"}) ? 
                    $::gProperties{"summary"} : '');
                    
              $description .= "$1\n";
                              
              setProperty("summary", $description);
    
   },
  },

);

push (@::gMatchers,
  {
   id =>        "generalSuccess",
   pattern =>          q{},
   action =>           q{
    
              my $description = ((defined $::gProperties{"summary"}) ? 
                    $::gProperties{"summary"} : '');
                    
              $description .= "$1\n";
                              
              setProperty("summary", $description);
    
   },
  },

);

push (@::gMatchers,
  {
   id =>        "errorDesc",
   pattern =>          q{errorDescr="(.+)"},
   action =>           q{
    
              my $description = ((defined $::gProperties{"summary"}) ? 
                    $::gProperties{"summary"} : '');
                    
              $description .= "$1\n";
                              
              setProperty("summary", $description);
    
   },
  },

);

push (@::gMatchers,
  {
   id =>        "unexpectedError",
   pattern =>          q{(.*Unexpected error.+)},
   action =>           q{
    
              my $description = "$1\n";
              setProperty("summary", $description);
    
   },
  },

);