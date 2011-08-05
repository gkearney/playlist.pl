#!/usr/bin/perl

BEGIN {
        push @INC,"/opt/local/lib/perl5/site_perl/5.8.8/";
}

use Cwd; # module for finding the current working directory
use File::Copy;
use File::Basename;
use MARC::Record;
use File::Path qw(make_path remove_tree);
#use Net::Twitter;
#use Net::Twitter::Lite;
use XML::Simple;
use Data::Dumper;
use Net::FTP;
#$mypath = "/Volumes/DaisyMasters/tmp";
#$mypath = "/Volumes/DaisyMasters/tmp";
$mypath = "/Volumes/DAISY_MASTER/tmp";



&ScanDirectory("$mypath");
&MoveDirectory("$mypath");
#&ScanDirectory("/Volumes/DaisyMasters/RNZFB");
#&ScanDirectory("/Users/gkearney/Desktop/tmp");





$dirname  = dirname($0);


sub MoveDirectory{
	my ($workdir) = shift; 

    my ($startdir) = &cwd; # keep track of where we began

    chdir($workdir) or die "Unable to enter dir $workdir:$!\n";
    opendir(DIR, ".") or die "Unable to open $workdir:$!\n";
    my @names = readdir(DIR) or die "Unable to read $workdir:$!\n";
    closedir(DIR);

    foreach my $name (@names){
    	next if ($name eq "."); 
        next if ($name eq "..");

		$new_name = $name;
		$new_name =~ s/\s+/_/g; #check for space
		$new_name =~ s/\x27//g; #check for space
		
        
        if (-d "$workdir/$name") {
    	
    	
    	&ScanDirectory("$workdir");
        next;
        
		chdir($startdir) #or  die "Unable to change to dir $startdir:$!\n";
    
    }


}
}



sub ScanDirectory{
	$record = '';
	$xml = '';
	$dirname  = dirname($0);
    my ($workdir) = shift; 

    my ($startdir) = &cwd; # keep track of where we began

    chdir($workdir) or die "Unable to enter dir $workdir:$!\n";
    opendir(DIR, ".") or die "Unable to open $workdir:$!\n";
    my @names = readdir(DIR) or die "Unable to read $workdir:$!\n";
    closedir(DIR);

    foreach my $name (@names){
        next if ($name eq "."); 
        next if ($name eq "..");
        #if ($name eq "Daisy_master") {
        	#print "removing $workdir/$name\n";
        	#remove_tree("$workdir/$name") or die "Could not unlink $workdir/$name $!";
        	#next;
        #}
        
        #This is here to remove the BackUp directory created by MyStudioPC.
		 if ($name eq "BackUp") {
        	print "removing $workdir/$name\n";
        	remove_tree("$workdir/$name") or die "Could not unlink $workdir/$name $!\n";
        	next;
        }

		if ($name eq "tmp") {
        	print "removing $workdir/$name\n";
        	remove_tree("$workdir/$name") or die "Could not unlink $workdir/$name $!\n";
        	next;
        }

        if (-d "$workdir/$name") { 
        	#removeing old files.
        	print "$workdir/$name\n";
        	$chmod = "chmod -Rv 775 $workdir/$name"; 
        	`$chmod`;
        	
            # is this a directory?
            if (!-e "$workdir/$name/*.wpl") {
            if (-e "$workdir/$name/AutoRun.exe") { unlink("$workdir/$name/AutoRun.exe"); }
        	if (-e "$workdir/$name/autorun.inf") { unlink("$workdir/$name/autorun.inf"); }
            
            if (-e "$workdir/$name/ncc.html") {
            	$cmd = "/usr/local/bin/pipeline/pipeline.sh /usr/local/bin/pipeline/scripts/modify_improve/multiformat/AudioTagger.taskScript --audioTaggerInputFile='$workdir/$name/ncc.html' --audioTaggerOutputPath='$workdir/$name'";


        		print "Working in $workdir/$name\n";
        		`$cmd`;
        		print "\tFinished $workdir/$name\n";
				
				print "Making MARC record from  $workdir/$name/ncc.html\n";



open FILE, "$workdir/$name/ncc.html" or die $!; #open the ncc.html file
			
$find = "dc:|ncc:"; #find only the lines with the meta data we need.
@line = <FILE>;
close FILE;

#loop through the file finding only lines with the meta data
for (@line) {
    if ($_ =~ /$find/) {
        $xml .= $_;
    }
}

if ($xml =~ m/<\/head>/gi) {
	$xml_head = "<head>\n$xml"; #put head tags around it for XML::Simple
} else {
	$xml_head = "<head>\n$xml</head>"; #put head tags around it for XML::Simple
}



#build the hash $ref key on the meta data name
$ref = XMLin($xml_head,ForceArray => 0, KeyAttr => 'name');


#Map the meta data into variables for the MARC record
#Map the meta data into variables for the MARC record
$title = $ref->{meta}->{'dc:title'}->{content};
$creator = $ref->{meta}->{'dc:creator'}->{content};
$date = $ref->{meta}->{'dc:date'}->{content};
$format = $ref->{meta}->{'dc:format'}->{content};
$uid = $ref->{meta}->{'dc:identifier'}->{content};
$language = $ref->{meta}->{'dc:language'}->{content};
$publisher = $ref->{meta}->{'dc:publisher'}->{content};
$totaltime = $ref->{meta}->{'ncc:totalTime'}->{content};
$subject = $ref->{meta}->{'dc:subject'}->{content};
$sourcepublisher = $ref->{meta}->{'ncc:SourcePublisher'}->{content};
$narrator = $ref->{meta}->{'ncc:narrator'}->{content};
$sourcedate = $ref->{meta}->{'ncc:SourceDate'}->{content};
$isbn = $ref->{meta}->{'dc:source'}->{content};



print "The format is: $format, The date is: $date\n";
				

close(FILE);


  
$record = '';
# create MARC object
$record = MARC::Record->new();

$marc_035 = MARC::Field->new(
   	'035','1','',
   		a => "$uid",
   		);

$marc_language = MARC::Field->new(
   	'041','1','',
   		a => "$language",
   		);

$marc_isbn = MARC::Field->new(
   	'020','1','',
   		a => "$isbn"
   		);
   		
$marc_author = MARC::Field->new(
   			'100','1','',
   			a => "$creator"
   			);

$marc_title = MARC::Field->new(
   	'245','1','4',
   		a => "$title",
   		c => "$creator"
   	);
   	

$marc_300 = MARC::Field->new(
   	'300','1','',
   		a => "$totaltime",
   		b => "$format mono"
   	);

$marc_500 = MARC::Field->new(
   	'500','1','',
   		a => "DAISY digital talking book ($format)"
   	);
   	
$marc_511 = MARC::Field->new(
   	'511','1','',
   		a => "$narrator"
   	);
   	
$marc_538 = MARC::Field->new(
   	'538','1','',
   		a => "DAISY digital talking books can be played on DAISY hardware playback devices or with a computer using DAISY playback software."
   	);
   	
#$marc_650 = MARC::Field->new(
 #  	'650','1','0',
#   		a => "$subject"
#   		);
   		
$marc_700 = MARC::Field->new(
   	'700','1','',
   		a => "$narrator",
   		e => "narrator"
   	);
   	
$marc_852 = MARC::Field->new(
   	'852','1','',
   		a => "$publisher"
   	);

$marc_260 = MARC::Field->new(
   	'260','1','',
   		a => "$publisher",
   		c => "$date"
   	);

$record->append_fields($marc_author, $marc_title, $marc_500, $marc_538, $marc_852, $marc_isbn, $marc_language, $marc_035, $marc_260, $marc_700, $marc_511, $marc_300) or print "Error creating MARC record\n"; 


open(OUTPUT, ">>$workdir/$name/daisy.mrc") or die $!;
print OUTPUT $record->as_usmarc();
close(OUTPUT);
$record = '';
print "\tFinished making MARC record from  $workdir/$name/ncc.html\n\n";



#Rename all the playlist files to the book title:


$newname = basename "$workdir/$name";
opendir DIR, "$workdir/$name";
@files = grep /playlist\.*/, readdir DIR;
closedir DIR;
 
foreach (@files) {
    
    $new = $_;
    $new =~ s/playlist\.(.+)/$newname.$1/;
    print "rename $_ $new\n";
    rename "$workdir/$name/$_", "$workdir/$name/$new";
}

rename "$workdir/$name/daisy.mrc", "$workdir/$name/$newname.mrc";
				
				
            }
            }
            
            &ScanDirectory("$workdir/$name");
            next;
        }
        

        


        	
        }
        
$name = basename $workdir;
print "Creating the zip file for $workdir/$name\n";
#$cmd = "cd $mypath; /usr/bin/zip -r $name $name > /dev/null &";
$cmd = "cd $mypath; /usr/bin/zip -r -0 $name $name > /dev/null ";
#print "$cmd\n";
`$cmd`;
sleep 3;

#test the zip file to see if it is OK
$result = `unzip -t $workdir.zip`;

if ($result =~ m/No errors detected/) {
	print "ZIP file OK";
} else {
	die "Error in ZIP file $workdir.zip";
}

$filesize = -s "$workdir.zip";

#Create the new directory on Bookserver-mac
@values = split('_',$name);

$dirnumber = @values[-1];

if ($dirnumber =~ /G.+/){
	$the_dir = "pd";
} else {
	$the_dir = "restricted";
}


if ($dirnumber =~ /[0-9]+/) {

if (!-d "/Volumes/books/$the_dir/$dirnumber") {
	make_path("/Volumes/books/$the_dir/$dirnumber", {
      verbose => 1,
      mode => 0777,
  });
} else {
	$rmcmd = "rm /Volumes/books/$the_dir/$dirnumber/*.*";
	`$rmcmd`;
}

$zmcmd = "mv -f $workdir.zip /Volumes/books/$the_dir/$dirnumber/$name.zip";
$zipmove = `$zmcmd`;
print "$zmcmd\n$zipmove\n";


if ($filesize > 100) {

if (!-d "/Volumes/DAISY_MASTER/ABWA/$name") {
	`mv -f $workdir /Volumes/DAISY_MASTER/ABWA`;
	print "Moving $workdir/$name to /Volumes/DAISY_MASTER/ABWA\n";
} else {
	print "/Volumes/DAISY_MASTER/ABWA/$name exists";	
}

}

#Send the book to twitter.
print "Sending the book information to Twitter.\n";

# $user = "AssocBlindWA";
# $password = ",abwa!";
# 
# my $nt = Net::Twitter::Lite->new(
#       username => $user,
#       password => $password
#   ) or print "Error login into twitter";



#my $nt = Net::Twitter->new(
#traits => [qw/OAuth API::REST/],
#consumer_key => "YFhiuQoaER4I6gXkWj4e2g",
#consumer_secret => "DGUGa3H4GJsugJbAPJHC5c0bj5CeqknJuj6Pjzl8vY",
#access_token => "41378378-PE6Y1yQisIwRPZ2mOMEQJUHVlrx2xl0JM34kHIN4j",
#access_token_secret => "YxozLo0RNzh1UktihTJET217eKNpcYXJqhV565tOPk",
#) or print "Error with twitter keys";
#
if ($creator eq '') {
	$author = "";
} else {
	$author = " by $creator";
}

if ($isbn) {
	$isbn_number = " ISBN: $isbn";
} else {
	$isbn_number = "";
}

if ($title ne "") {
`/Resources/twitter.sh "$title$author$isbn_number has been converted to DAISY."`;

#	$t_result = $nt->update("$title$author$isbn_number has been converted to DAISY.") or print "Error sending to twitter";
}
#
#print "Twitter replied with $t_results\n";
}



chdir($startdir) or  die "Unable to change to dir $startdir:$!\n";
#`mv  $workdir/$name /Volumes/DaisyMasters/ABWA`;



  
  

}
        
        
      




print "\nSCAN FINISHED\n";