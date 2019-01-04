# -------------------------------------------------------------------------
   # File
   #    sendUCSRequest.pl
   #
   # Dependencies
   #    None
   #
   # Template Version
   #    1.0
   #
   # Date
   #    11/05/2010
   #
   # Engineer
   #    Alonso Blanco
   #
   # Copyright (c) 2011 Electric Cloud, Inc.
   # All rights reserved
   # -------------------------------------------------------------------------
   
   
   # -------------------------------------------------------------------------
   # Includes
   # -------------------------------------------------------------------------
   use ElectricCommander;
   use ElectricCommander::PropDB;
   use LWP::UserAgent;
   use HTTP::Request;
   use XML::Simple;
   use Data::Dumper;
   use warnings;
   use strict;
   $|=1;
   
   # -------------------------------------------------------------------------
   # Constants
   # -------------------------------------------------------------------------
   use constant {
       SUCCESS => 0,
       ERROR   => 1,
       
       TRUE => 1,
       FALSE => 0,
       
       PLUGIN_NAME => 'EC-CiscoUCS',
       CREDENTIAL_ID => 'credential',
       
       SCRIPT_FILE_MODE_EMBEDDED => 'embeddedfile',
       SCRIPT_FILE_MODE_EXISTENT => 'existentfile',
       
       GENERATE_REPORT => 1,
       DO_NOT_GENERATE_REPORT => 0,
       
       LOGIN_XML_TEMPLATE => '<aaaLogin inName="" inPassword="" />',
       LOGOUT_XML_TEMPLATE => '<aaaLogout inCookie="" />',
       
       
   
  };
  
  ########################################################################
  # trim - deletes blank spaces before and after the entered value in 
  # the argument
  #
  # Arguments:
  #   -untrimmedString: string that will be trimmed
  #
  # Returns:
  #   trimmed string
  #
  #########################################################################
  sub trim($) {
   
      my ($untrimmedString) = @_;
      
      my $string = $untrimmedString;
      
      #removes leading spaces
      $string =~ s/^\s+//;
      
      #removes trailing spaces
      $string =~ s/\s+$//;
      
      #returns trimmed string
      return $string;
  }  
  
  # -------------------------------------------------------------------------
  # Variables
  # -------------------------------------------------------------------------
  
  $::gConfigName = "$[configname]";
  $::gScriptMode = "$[scriptfilemode]";
  $::gEmbeddedFile = trim(q($[scriptfilecontent]));
  $::gScriptFilePath = trim(q($[scriptfilepath]));
  
  $::gURL = '';
  $::gUser = '';
  $::gPassword = '';
  
  $::gCookie = '';
  
  # -------------------------------------------------------------------------
  # Main functions
  # -------------------------------------------------------------------------
  
  
  ########################################################################
  # main - contains the whole process to be done by the plugin, it builds 
  #        the command line, sets the properties and the working directory
  #
  # Arguments:
  #   none
  #
  # Returns:
  #   none
  #
  ########################################################################
  sub main() {
   
    # get an EC object
    my $ec = new ElectricCommander();
    $ec->abortOnError(0);
      
    # create args array
    my %props;
    
    my %configuration;
    
    my $obtainedResponse = '';
    my $obtainedContent = '';
    
    my $loginRequest = '';
    my $loginResponse = '';
    my $logoutRequest = '';
    
    my $userContent = '';
    
    #getting all info from the configuration, url, user and pass
    if($::gConfigName ne ''){
        %configuration = getConfiguration($::gConfigName);
        
        getDataFromConfig(\%configuration, \$::gURL, \$::gUser, \$::gPassword);
        
    }

    #create all objects needed for response-request operations
    my $agent = LWP::UserAgent->new(env_proxy => 1,keep_alive => 1, timeout => 30);
    
    print "Creating Request Header to $::gURL...\n";
    my $header = HTTP::Request->new(POST => $::gURL);

    print "Creating Request to $::gURL...\n";
    my $request = HTTP::Request->new('POST', $::gURL, $header);
    $request->content_type('text/xml');
    
    #login
    
    #attach login template 
    $loginRequest = LOGIN_XML_TEMPLATE;
    
    #enter credentials
    $loginRequest =~ s/inName=\"\" inPassword=\"\"/inName=\"$::gUser\" inPassword=\"$::gPassword\"/;
    
    #attach login xml file to a request object
    $request->content($loginRequest);
    
    print "Sending Login Request:\n$loginRequest\nTo $::gURL...\n\n";
    
    #execute login request
    my $response = $agent->request($request);
    
    print "Login response:\n---------------\n".$response->content()."\n---------------\n";
    
    # Check the outcome of the response
    if ($response->is_success){
        
        #get login response from request
        $loginResponse = $response->content();
        
        #retrieve the cookie from the login
        if($loginResponse =~ m/outCookie="(\S+)"/){
            $::gCookie = $1;
        }else{
            print "Error: couldn't retrieve cookie from login request.\n";
            exit ERROR;
        }
        
    }elsif ($response->is_error){
     
        print "Unexpected error occurred while logging in. Cannot continue.\n";
        $ec->setProperty("/myJobStep/outcome", 'error');
        exit ERROR;
    }
    
    #execute check
    if($::gScriptMode eq SCRIPT_FILE_MODE_EXISTENT){
       
       if($::gScriptFilePath && $::gScriptFilePath ne '') {
          
           print "Using external script file: $::gScriptFilePath\n\n";
           my $fileContent = '';
           
           #read contents from the given script file path
           my $data_file = $::gScriptFilePath;
           open(DATA, $data_file) || die("Could not open file.");
           my @raw_data = <DATA>;
           close(DATA);
           
           #retrieve file contents
           foreach my $line (@raw_data){
              $fileContent .= $line;
           }
           
           #assuring file is not empty
           if($fileContent ne ''){
               
               #applying cookie...
               $fileContent =~ s/cookie="(\S*)"/cookie="$::gCookie"/;
               
               #attaching obtained file content
               $request->content($fileContent);
               
               print "Sending:\n$fileContent\n\n";
               
           }else{
            
               #file is empty, user is informed
               print "Error: Given Script file is empty, cannot proceed.\n";
               exit ERROR;
            
           }
           
       }
       
    }elsif($::gScriptMode eq SCRIPT_FILE_MODE_EMBEDDED){
     
        print "Using embedded script file\n\n";
        
        #applying cookie...
        $::gEmbeddedFile =~ s/cookie="(\S*)"/cookie="$::gCookie"/;
        
        #set content into request
        $request->content($::gEmbeddedFile);
        
        print "Sending:\n$::gEmbeddedFile\n\n";
     
    }
    
    print "Sending Request to $::gURL...\n\n";
    $response = $agent->request($request);
    
    $obtainedResponse = $response->as_string;
    $obtainedContent = $response->content();
     
    print "Response obtained:\n---------------\n$obtainedResponse\n---------------\n";
    
    # Check the outcome of the response
    if ($response->is_success){
        
        if($obtainedResponse =~ m/errorDescr="(.+)"/){
            print "UCS Server sent an error response: $1\n";
            $ec->setProperty("/myJobStep/outcome", 'error');
        }
        
        if($obtainedResponse =~ m/errorCode="(\d+)"/){
            print "Error Code: $1\n";
            $ec->setProperty("/myJobStep/outcome", 'error');
        }
        
    }elsif ($response->is_error){
        print "Unexpected error occurred\n";
        $ec->setProperty("/myJobStep/outcome", 'error');
    }
    
    #attach obtained xml file location
    my $responseFileName = "UCSXMLResponse.xml";
    open (NEWFILE, ">>$responseFileName");
    print NEWFILE "$obtainedContent";
    close (NEWFILE);
    
    my $xmlRelativeHTTPLocation = "jobSteps/$[jobStepId]/$responseFileName";
    my $configDataForReport = '';
    
    if($obtainedContent =~ m/<outConfig>(.+)<\/outConfig>/){
     
        #link obtained XML File, this should be useful for queries responses
        registerReports($xmlRelativeHTTPLocation, 'UCS Response File');
        
        my $ucsConfigData = $1;
        
        # create XML object
        my $xml = new XML::Simple;

        # read XML file
        my $data = $xml->XMLin($ucsConfigData);
        
        my $valuesAsString = '';

        #print Dumper($data);

        foreach my $attributes (keys %{$data}){
            #print "$attributes : ${$data}{$attributes}\n";
            $valuesAsString .= "$attributes~~${$data}{$attributes};;";
        }
        
        registerReports("/commander/pages/$[/myProject/projectName]/reports?jobId=$[jobId]&report=$valuesAsString", 'UCS Report');
        
    }
    
    #logout
    $logoutRequest = LOGOUT_XML_TEMPLATE;
    $logoutRequest =~ s/inCookie=\"\"/inCookie=\"$::gCookie\"/;
    
    $request->content($logoutRequest);
    
    print "Sending Logout Request\n$logoutRequest\nTo$::gURL...\n\n";
    $response = $agent->request($request);
    
    $obtainedResponse = $response->as_string;
    
    # Check the outcome of the response
    if ($response->is_success){
        
        print "Logout response:\n---------------\n".$response->content()."\n---------------\n";
        
        if($obtainedResponse =~ m/errorDescr="(.+)"/){
            print "UCS Server sent an error response: $1\n";
            $ec->setProperty("/myJobStep/outcome", 'error');
        }
        
        if($obtainedResponse =~ m/errorCode="(\d+)"/){
            print "Error Code: $1\n";
            $ec->setProperty("/myJobStep/outcome", 'error');
        }
        
    }elsif ($response->is_error){
        print "Unexpected error occurred\n";
        $ec->setProperty("/myJobStep/outcome", 'error');
    }
    
    setProperties(\%props);
    
  }
  
  ########################################################################
  # setProperties - set a group of properties into the Electric Commander
  #
  # Arguments:
  #   -propHash: hash containing the ID and the value of the properties 
  #              to be written into the Electric Commander
  #
  # Returns:
  #   none
  #
  ########################################################################
  sub setProperties($) {
   
      my ($propHash) = @_;
      
      # get an EC object
      my $ec = new ElectricCommander();
      $ec->abortOnError(0);
      
      foreach my $key (keys % $propHash) {
          my $val = $propHash->{$key};
          $ec->setProperty("/myCall/$key", $val);
      }
  }
  
  ########################################################################
  # registerReports - creates a link for registering the generated report
  # in the job step detail
  #
  # Arguments:
  #   -reportFilename: name of the archive which will be linked to the job detail
  #   -reportName: name which will be given to the generated linked report
  #
  # Returns:
  #   none
  #
  ########################################################################
  sub registerReports($){
      
      my ($target, $reportName) = @_;
      
      if($target && $target ne ''){
          
          # get an EC object
          my $ec = new ElectricCommander();
          $ec->abortOnError(0);
          
          $ec->setProperty("/myJob/artifactsDirectory", '');
                  
          $ec->setProperty("/myJob/report-urls/$reportName", $target);
      
      }
      
  }
  
  ##########################################################################
  # getConfiguration - get the information of the configuration given
  #
  # Arguments:
  #   -configName: name of the configuration to retrieve
  #
  # Returns:
  #   -configToUse: hash containing the configuration information
  #
  #########################################################################
   sub getConfiguration($){
   
      my ($configName) = @_;
      
      # get an EC object
      my $ec = new ElectricCommander();
      $ec->abortOnError(0);
      
      my %configToUse;
      
      my $proj = "$[/myProject/projectName]";
      my $pluginConfigs = new ElectricCommander::PropDB($ec,"/projects/$proj/ucs_cfgs");
      
      my %configRow = $pluginConfigs->getRow($configName);
      
      # Check if configuration exists
      unless(keys(%configRow)) {
          print 'Error: Configuration doesn\'t exist';
          exit ERROR;
      }
      
      # Get user/password out of credential
      my $xpath = $ec->getFullCredential($configRow{credential});
      $configToUse{'user'} = $xpath->findvalue("//userName");
      $configToUse{'password'} = $xpath->findvalue("//password");
      
      foreach my $c (keys %configRow) {
          
          #getting all values except the credential that was read previously
          if($c ne CREDENTIAL_ID){
              $configToUse{$c} = $configRow{$c};
          }
          
      }
     
      return %configToUse;
   
  }
  
  sub getDataFromConfig($){
   
        my($configuration, $url, $user, $pass) = @_;
        
        if($configuration->{'ucs_url'} && $configuration->{'ucs_url'} ne ''){
            ${$url} = $configuration->{'ucs_url'};
        }else{
            print 'Could not get URL from configuration '. $::gConfigName;
            exit ERROR;
        }
        
        if($configuration->{'user'} && $configuration->{'user'} ne ''){
            ${$user} = $configuration->{'user'};
        }else{
            print "Could not get user from configuration $::gConfigName";
            exit ERROR;
        }
        
        if($configuration->{'password'} && $configuration->{'password'} ne ''){
            ${$pass} = $configuration->{'password'};
        }else{
            print "Could not get password from configuration $::gConfigName\n";
            exit ERROR;
        }
   
  }
  
  main();
   
  1;
