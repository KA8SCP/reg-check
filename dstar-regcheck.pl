#!/usr/bin/perl
#
# DStar-Registrierungs-Check
#
# (C) Hans-J. Barthen, DL5DI
#     Franz-Josef-Str. 20
#     D-56642 Kruft
#
# 2009-09-19 start of development
# 2009-12-29 find more errors (double registration, terminals registered at dif
# 2010-01-25 show IP address range (startip + 7)
# 2010-01-26 check if terminal-IP is in dedicated IP-range
# 2010-04-01 check for terminals even if no user registration exists
# 2010-09-15 check for database entries created by ircDDB
# 2010-09-17 first multi-language version
# 2010-09-22 bugfix, text $t21 (hit-counter) was accidently called $t20
# 2010-10-17 bugfix, hitcounter not set before use
# 2010-12-17 converted to Hamnet
# 2012-03-28 check if callsign is a registered gateway

use LWP::Simple

$| = 1;		# flush print and write
$rev = "2017/03/16";

if(substr($ENV{'HTTP_ACCEPT_LANGUAGE'}, 0, 2) eq "de"){
    $language = "DE";
    $t00 = "<td><b><font size=+2>DStar-Gateway Registrierungs-Check</center></font></b></td>";
    $t01 = "<hr><center><form action=\"/cgi-bin/dstar-regcheck\" method=get>Callsign:<input name=\"callsign\" size=10 maxlength=7 value=\"\"><input TYPE=\"SUBMIT\" VALUE=\"SUCHE\"></form></center>";
} else {
    $t00 = "<td><b><font size=+2>DStar-Gateway Registration Check</center></font></b></td>";
    $t01 = "<hr><center><form action=\"/cgi-bin/dstar-regcheck\" method=get>Callsign:<input name=\"callsign\" size=10 maxlength=7 value=\"\"><input TYPE=\"SUBMIT\" VALUE=\"SUBMIT\"></form></center>";
}

###################### HTML-Header ########################

print("<!doctype html public \"-//w3c//dtd html 4.0 transitional//en\">");
print("<html>");
print("<head>");
print("   <meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\">");
print("   <meta name=\"Author\" content=\"Hans-Juergen Barthen, DL5DI\">");
print("   <meta name=\"GENERATOR\" content=\"dstar-regcheck.pl DL5DI 12/2009\">");
print("   <META HTTP-EQUIV=\"Pragma\" CONTENT=\"no-cache\">");
print("   <title>DStar-Repeater/Gateway - KB1SBJ<br>Registration-Check</title>");
print("</head>");
print("<body>");

print("<table CELLPADDING=5>");
print("<tr>");
print("<td>");

print("<table CELLPADDING=5>");
print("<tr>");
print("<td><img SRC=\"/USA.jpg\" BORDER=0 height=30 width=50></td>");
print"$t00";
print("<td><a href=\"http://www.ircddb.net\"><img SRC=\"/dstar_logo.jpg\" BORDER=0 height=60 width=120></a></td>");
print("</tr>");
print("</table>");

#print "$client_language<p>";

# This is a local banner. Print it only if called on our own website:
$ref = $ENV{'HTTP_REFERER'};
#if(index($ref,"prgm.org") > 0){
#    print("<center><b><i><font color=red size=+3>Wir linken <a href=\"http://dstar.prgm.org/dstar-dplus.html\">DPlus</a> und <a href=\"http://dstar.prgm.org/dstar-dextra.html\">DExtra</a>!</font></i></b></center>");
#}
#----- Request callsign ------

print("<p>&nbsp");
print"$t01";
print("<hr>");
print("&nbsp<br>");

$owncall = "KB1SBJ";
$callsign = $ARGV[0];

if($callsign){

    $callsign =~ tr/a-z/A-Z/;

    use DBI;

    my $dbname = "dstar_global";
    my $user = "dstar";
    my $pass = "icom";
    my $hostname = "127.0.0.1";

    my $table1 = "sync_rip";
    my $table2 = "sync_mng";
    my $table3 = "sync_gip";
    
    ($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst)=gmtime(time);
    $mon++;
    $year+=1900;

    my $Timestamp = sprintf("%4.4d/%2.2d/%2.2d %2.2d:%2.2d",$year,$mon,$day,$hour,$min);


# read and increase hit counter
    if (open(CNTFILE, "/var/local/httpd/cgi-bin/dstar-regcheck.cnt")) {
	$cnt = <CNTFILE>;
        close(CNTFILE);
	chop($cnt);
        $cnt++;
    } else {
	$cnt = 1;
    }    

# write counter back to file
    if (open(CNTFILE, ">/var/local/httpd/cgi-bin/dstar-regcheck.cnt")) {
	printf(CNTFILE "$cnt\n");
	close(CNTFILE);
    }

    if($language eq "DE"){
	$t1 = "<p><br><font size=+1><center><b>Registrierungs-Info:</b></center></font>"; # Ueberschrift
	$t2 = "<tr><td><center>Registr.Call</center></td><td><center>Registrierungsserver</center></td><td><center>Datum der Registrierung</center></td><td><center>IP-Address-Pool</center></td></tr>"; # Tabelle 1
	$t3 = "<BR><font size=+1><b>Es existiert keine Registrierung!</b></font><P>";
	$t4 = "<br><font size=+1><center><b>Folgender Registrierungs-Eintrag wurde gel&ouml;scht:</b></center></font><br>";
	$t5 = "<tr><td><center>Call/ID</center></td><td><center>Registrierungsserver</center></td><td><center>L&ouml;schdatum</center></td></tr>";
	$t6 = "<p><br><font size=+1><center><b>Dieser Eintrag wurde lokal von ircDDB generiert</center></font>";
	$t7 = "<p><br><font size=+1><center><b>F&auml;lschlicherweise noch aktivierte <a href=\"http://dstar.prgm.org/DStarTerminalIDs.html\" >Terminal-IDs:</a></b></center></font>";
	$t8 = "<p><br><font size=+1><center><b>Aktivierte <a href=\"http://dstar.prgm.org/DStarTerminalIDs.html\" >Terminal-IDs:</a></b></center></font>";
	$t9 = "<tr><td><center>Device Call/ID</center></td><td><center>Registrierungsserver</center></td><td><center>IP-Adresse</center></td><td><center>Letztmals geh&ouml;rt</center></td><td><center> Repeater </center></td><td><center> Gateway </center></td></tr>";
    	$t10 = "<BR><font size=+1><b>Mehrfachregistrierung!</b></font>";
    	$t11 = "<BR><font size=+1><b>Terminalanmeldung fehlerhaft!</b></font>";
    	$t12 = "<BR><font size=+1><b>Fehlender Eintrag mit leerer ID / Leerzeichen!</b></font>";
    	$t13 = "<BR><font size=+1><b>Registrierung bitte beim Registrierungsserver <font size=+2>$regsrv</font> komplettieren!</b></font>";
	$t14 = "<BR><font size=+1><b>Mehr Informationen zum <a href=\"http://dstar.prgm.org/DStar-Registrierung.htm\">Registrierungsvorgang hier!</a></b></font>";
    	$t15 = "<P><font size=+1 color=red><b>Registrierung NICHT OK!</b></font>";
    	$t16 = "<P><font size=+1 color=red><b>Registrierung NICHT OK!<br>(IP ausserhalb des zugewiesenen Adress-Pools)</b></font>";
    	$t17 = "<P><font size=+1><b>Registrierung OK!</b></font>";
    	$t18 = "<P><font size=+1><b>Terminalanmeldung OK f&uuml;r ircDDB-Netzwerk!</b></font>";
    	$t19 = "<center><br><font size=+1><b>Existierende Terminals m&uuml;ssen vom Admin des neuen<br>Registrierungs-Servers gel&ouml;scht werden.<br>Bitte nach dem ersten Registrierungsschritt bei ihm melden!</b></font><p>";
	$t20 = "<BR><center><font size=+1><a href=\"http://dstar.prgm.org/dstar-reg.htm\" target =\"_blank\" > Registrierung z.B. hier bei KB1SBJ </a></font><BR><center><font size=+1><a href=\"https://db0hrf.ham-radio-op.net/Dstar.do\" target =\"_blank\" > oder bei DB0HRF m&ouml;glich</a></font><BR>";
	$t21 = "<center><i>$cnt Abrufe seit 20090817</font></i><br>";	# Abrufe seit Installationsdatum - einfuegen !!
	$t22 = " ist ein registriertes <a href=\"http://www.dstarusers.org/repeaters.php\" target=\"_blank\">US-Trust-Gateway</a>";
	$t23 = " ist ein registriertes <a href=\"http://status.ircddb.net/cgi-bin/ircddb-gwst\" target=\"_blank\">ircDDB-Gateway</a>";
	$t24 = "<BR>Bei einem Gateway sollte die leere ID (Leerzeichen) <u>NICHT</u><br> registriert sein, da dies Routingprobleme verursachen kann!<br>";
    } else {
	$t1 = "<p><br><font size=+1><center><b>Registration Information:</b></center></font>"; # Headline
	$t2 = "<tr><td><center>Registr.Call</center></td><td><center>Registration Server</center></td><td><center>Date of Registration</center></td><td><center>IP-Address-Pool</center></td></tr>"; # table 1
	$t3 = "<BR><font size=+1><b>No Registration!</b></font><P>";
	$t4 = "<br><font size=+1><center><b>The following Registration-Record had been erased:</b></center></font><br>";
	$t5 = "<tr><td><center>Call/ID</center></td><td><center>Registration Server</center></td><td><center>Date of erase</center></td></tr>";
	$t6 = "<p><br><font size=+1><center><b>This entry was created locally by ircDDB</center></font>";
	$t7 = "<p><br><font size=+1><center><b>Orphan <a href=\"http://dstar.prgm.org/DStarTerminalIDs.html\" >Terminal-IDs:</a></b></center></font>";
	$t8 = "<p><br><font size=+1><center><b>Activated <a href=\"http://dstar.prgm.org/DStarTerminalIDs.html\" >Terminal-IDs:</a></b></center></font>";
	$t9 = "<tr><td><center>Device Call/ID</center></td><td><center>Registration Server</center></td><td><center>IP-Address</center></td><td><center>Last Heard</center></td><td><center> Repeater </center></td><td><center> Gateway </center></td></tr>";
    	$t10 = "<BR><font size=+1><b>Multi Registration!</b></font>";
    	$t11 = "<BR><font size=+1><b>Wrong Terminal registration!</b></font>";
    	$t12 = "<BR><font size=+1><b>Missing Eintry with Space-ID!</b></font>";
    	$t13 = "<BR><font size=+1><b>Please complete registration at Registrationserver <font size=+2>$regsrv</font> !</b></font>";
	$t14 = "<BR><font size=+1><b>More informationen on the <a href=\"http://dstar.prgm.org/DStar-Registrierung.htm\">registration process!</a></b></font>";
    	$t15 = "<P><font size=+1 color=red><b>Registration NOT OK!</b></font>";
    	$t16 = "<P><font size=+1 color=red><b>Registration NOT OK!<br>(IP outside of assigned pool!)</b></font>";
    	$t17 = "<P><font size=+1><b>Registration OK!</b></font>";
    	$t18 = "<P><font size=+1><b>Registration OK for ircDDB-Network!</b></font>";
	$t19 = "<center><br><font size=+1><b>Existing Terminals have to be deleted by the Admin of the <br>new Registration-Servers.<br>Please contact him after the first step of the Registration process!</b></font><p>";
	$t20 = "<BR><center><font size=+1><a href=\"http://dstar.prgm.org/dstar-reg.htm\" target =\"_blank\" > Registration is possible at $owncall </a></font>";
	$t21 = "<center><i>$cnt hits since 20100917</font></i><br>";  # hits since installation - enter installation date here !
	$t22 = " is a registered <a href=\"http://www.dstarusers.org/repeaters.php\" target=\"_blank\">US-trust gateway</a>";
	$t23 = " is a registered <a href=\"http://status.ircddb.net/cgi-bin/ircddb-gwst\" target=\"_blank\">ircDDB gateway</a>";
	$t24 = "<BR>The Space-ID should <u>NOT</u> be registered for a gateway, it may create routing issues!<br>";
    }


#----- connect db -------

    my $dsn = "DBI:Pg:database=$dbname;host=$hostname";
    my $dbh = DBI->connect( $dsn, $user, $pass ) || die DBI::errstr;

#----- read table1 ------

    $sql= "SELECT regist_rp_cs, last_mod_time, start_ipaddr FROM $table1 WHERE user_cs = '$callsign' And del_flg = 'FALSE'";

#print "SQL-Command: $sql\n";

    $sth = $dbh->prepare($sql);
    $num = $sth->execute();


######################################################################

# Table start
    print"$t1";
    print("<center><table BORDER CELLSPACING=0 CELLPADDING=0 BGCOLOR=\"#33CCFF\" >");
    print"$t2";

#    my @data = $sth->fetchrow_array;
    $rs = 0;
    $userreg = 0;
    while (my @data = $sth->fetchrow_array) {
	$userreg++;
	print("<tr>");
        printf("<td ALIGN=CENTER>%8s</td>",$callsign); # Terminal Call
	printf("<td ALIGN=CENTER>%7s</td>",$data[0]); # Registration Server
	if($rs == 0){
	    $regsrv = $data[0];
	}
        printf("<td ALIGN=CENTER>%20s</td>",$data[1]);  # Last Mod
	$startip = $data[2];
	($h1,$h2,$h3,$h4) = split(/\./,$startip);
	$startipdez = 16777216 * $h1 + 65536 * $h2 + 256 * $h3 + $h4;
	$h4 += 7;
	$endipdez = $startipdez + 7;
	$endip = sprintf("%s.%s.%s.%s",$h1,$h2,$h3,$h4);
        printf("<td ALIGN=CENTER>%s-<br>%s</td>",$startip,$endip);  # Start IP-Address
	print("</tr>");
	$rs++;
    }
    print("</table>");
#print "$rs\n";

    if(!$regsrv) {
	print"$t3";
	
	my $sql= "SELECT regist_rp_cs, last_mod_time FROM $table1 WHERE user_cs = '$callsign' And del_flg = 'TRUE'";

	my $sth = $dbh->prepare($sql);
	my $num = $sth->execute();

	my @data = $sth->fetchrow_array;

	if($data[0]){
# Table start
	    print "$t4";
	    print("<center><table BORDER CELLSPACING=0 CELLPADDING=0 BGCOLOR=\"RED\" >");
	    print "$t5";
	    print("<tr>");
	    printf("<td ALIGN=CENTER>%8s</td>",$callsign); # Terminal-Call
	    printf("<td ALIGN=CENTER>%7s</td>",$data[0]); # Registrierungsserver
	    printf("<td ALIGN=CENTER>%20s</td>",$data[1]);  # Letzte Aenderung
	    print("</tr>");
	    print("</table>");
	}
    }

#----- read table2 ------

    my $sql= "SELECT target_cs, last_mod_time, regist_rp_cs, pc_ipaddr, arearp_cs, zonerp_cs, del_flg FROM $table2 WHERE user_cs = '$callsign' And del_flg = 'FALSE'";

#print "SQL-Command: $sql\n";
    my $sth = $dbh->prepare($sql);
    my $num = $sth->execute();

# Table start

    $i = 0;
    $sp_entry = 0;
    $termerr = 0;
    $ircddb = 0;
    $iperr = 0;

    while (my @data = $sth->fetchrow_array) {
        ($h1,$h2,$h3,$h4) = split(/\./,$data[3]);
        $termipdez = 16777216 * $h1 + 65536 * $h2 + 256 * $h3 + $h4;
	if($termipdez == "0.0.0.0"){
	    $ircddb = 1;
	}
	if ($i == 0){
	    if($userreg == 0){
		if($ircddb){
		    print"$t6";
		} else {
		    print"$t7";
		}
	    } else {
		print"$t8";
	    }
	    print("<center><table BORDER CELLSPACING=0 CELLPADDING=0 BGCOLOR=\"#33CCFF\" >");
	    print"$t9";
	}
        print("<tr>");
        printf("<td ALIGN LEFT>%8s</td>",$data[0]); # Terminal-Call
        printf("<td ALIGN=CENTER>%15s</td>",$data[2]); # RegServ
        if(($termipdez < $startipdez) || ($termipdez > $endipdez)) {
	    printf("<td ALIGN=CENTER>%15s</td>",$data[3]); # IP-address
	    $iperr++;
	} else {
	    printf("<td ALIGN=CENTER>%15s</td>",$data[3]); # IP-address
	}
        printf("<td ALIGN=CENTER>%20s</td>",$data[1]); # last change
        printf("<td ALIGN LEFT>%8s</td>",$data[4]); # ZoneRP
        printf("<td ALIGN LEFT>%8s</td>",$data[5]); # AreaRP
	print("</tr>");
	if($regsrv ne $data[2]) {
	    $termerr = 1;
	}
#print "$termerr\n";		
	$id = substr($data[0],7,1);
#print"<br>ID:-$id-<br>";
	if($id eq " ") {
	    $sp_entry = 1;
	}
	$i++;
    }

# Table end
    if($i > 0){
	print("</table>");
    }

    $err = 0;

#----- check in table 3 if it is a registered US-trust gateway -------

    $gateway = 0;
    $sql= "SELECT * FROM $table3 WHERE zonerp_cs = '$callsign' And del_flg = 'FALSE'";

#print "SQL-Command: $sql\n";

    $sth = $dbh->prepare($sql);
    $num = $sth->execute();
    $ustrust = $sth->rows();

    if($ustrust > 0){
	printf("<br><b>%s %s</b>",$callsign,$t22);
	$gateway = 1;
    }

#----- check at ircddb.net if it is a registered ircDDB gateway -------

    $url = "http://status.ircddb.net/isgw.php?call=$callsign";
    $ircddb = get($url);

    if($ircddb > 0){
	printf("<br><b>%s %s</b>",$callsign,$t23);
	$gateway = 1;
    }

    if($userreg > 0){

	if($rs > 1) {
    	    print"$t10";
    	    $err = 1;
	} 
	if($termerr > 0) {
    	    print"$t11";
    		$err = 1;
	} 

	if($sp_entry == 0) {
	    if($gateway == 0){
    		print"$t12";
    		$err = 1;
    		print"$t13";
    		if(index($regsrv,$owncall) == 0){
		    print"$t14";
		}
	    }	    
	} else {
	    if($gateway == 1){
		print"$t24";
		$err++;
	    }
	}
	if($err > 0){
    	    print"$t15";
	} elsif ($iperr > 0) {
    	    print"$t16";
	} else {
    	    print"$t17";
	}
    } else {
	if ($i > 0){
	    if($ircddb){
    		print"$t18";
    	        $err = 0;
	    } else {
    		print"$t19";
	    }
	}
        if(!$ircddb){
    		print"$t20";
	}
    }

#print "<br>US-Trust:$ustrust<br>ircDDB:$ircddb<br>";

    print("<BR>&nbsp<br>");
#    print"$t21";
    print "<center>Status: $Timestamp UTC<br>";
    print "<center>Software-Rev.: $rev (dl5di)<br>";
#    print "Referer: $ref";
    print("</center></table>");
#------ DB close ------

    $sth->finish;
    $dbh->disconnect;
}
###################### HTML-Footer ################################
#

print("</body>");
print"</html>";

###
