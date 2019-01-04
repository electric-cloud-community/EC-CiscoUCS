# The plugin is being promoted, create a property reference in the server's property sheet
# Data that drives the create step picker registration for this plugin.
my %SendUCSRequest = (
			   label       => "Cisco UCS - Send Request",
			   procedure   => "SendUCSRequest",
			   description => "Send a Cisco UCS Request.",
			   category    => "Resource Management"
			  );


@::createStepPickerSteps = (\%SendUCSRequest);

$batch->deleteProperty("/server/ec_customEditors/pickerStep/Cisco UCS - Send Request");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/Cisco UCS - sendRequest");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/Cisco UCS - SendRequest");

if ($upgradeAction eq "upgrade") {
 
    my $query = $commander->newBatch();
    my $newcfg = $query->getProperty("/plugins/$pluginName/project/ucs_cfgs");
    my $oldcfgs = $query->getProperty("/plugins/$otherPluginName/project/ucs_cfgs");
	my $creds = $query->getCredentials("\$[/plugins/$otherPluginName]");

	local $self->{abortOnError} = 0;
    $query->submit();

    # if new plugin does not already have cfgs
    if ($query->findvalue($newcfg,"code") eq "NoSuchProperty") {
        # if old cfg has some cfgs to copy
        if ($query->findvalue($oldcfgs,"code") ne "NoSuchProperty") {
            $batch->clone({
                path => "/plugins/$otherPluginName/project/ucs_cfgs",
                cloneName => "/plugins/$pluginName/project/ucs_cfgs"
            });
        }
    }
	
	# Copy configuration credentials and attach them to the appropriate steps
    my $nodes = $query->find($creds);
    if ($nodes) {
        my @nodes = $nodes->findnodes("credential/credentialName");
        for (@nodes) {
            my $cred = $_->string_value;

            # Clone the credential
            $batch->clone({
                path => "/plugins/$otherPluginName/project/credentials/$cred",
                cloneName => "/plugins/$pluginName/project/credentials/$cred"
            });

            # Make sure the credential has an ACL entry for the new project principal
            my $xpath = $commander->getAclEntry("user", "project: $pluginName", {
                projectName => $otherPluginName,
                credentialName => $cred
            });
            if ($xpath->findvalue("//code") eq "NoSuchAclEntry") {
                $batch->deleteAclEntry("user", "project: $otherPluginName", {
                    projectName => $pluginName,
                    credentialName => $cred
                });
                $batch->createAclEntry("user", "project: $pluginName", {
                    projectName => $pluginName,
                    credentialName => $cred,
                    readPrivilege => 'allow',
                    modifyPrivilege => 'allow',
                    executePrivilege => 'allow',
                    changePermissionsPrivilege => 'allow'
                });
            }

            $batch->attachCredential("\$[/plugins/$pluginName/project]", $cred, {
                procedureName => 'SendUCSRequest',
                stepName => 'RunUCSRequest'
            });
            
        }
    }

}
