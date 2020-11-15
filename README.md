# reg-check
Perl-Module LWP::simple: required
Perl-Module CGI required to make script stand alone
Perl database connectors required for PostgresSQL


# Install

1. Get required files
```sh
yum install perl-libwww-perl perl-DBD-Pg perl-CGI
```
2. Install dstar-regcheck to /var/www/html/cgi-bin from this repo
- change "GW-CALL" to own gateway callsign
```sh
sed -i 's/GW-CALL/N0CALL/g' /var/www/html/cgi-bin
```
3. Get some other html documentation that helps users
```sh
cd /var/www/html
wget https://w9dua.dstargateway.org/DStarTerminalIDs.html
```
