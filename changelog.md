# Image Change Log

## WIP

## Version 0.3 (Thu, Jan 1 2026)
* Added proper logging
* Updated /app/init/init.sh file with the following
   * Proper logging
   * Reorder file executions (moved files around where they made more sense to be ran)
   * Removed Bash's sed commands due to flaky file updates
   * Added new Perl script to update .ldif files properly
   * Send command outputs to /dev/null to reduce noise and properly logged progress to the console
* Added new Perl script called /app/init/update_files.pl to update .ldif files
* Updated /app/init/ldap_ssl.ldif to replace the "add" command at line 3 with the "replace" command since this field already exists within the LDAP server
* Updated /app/entrypoint.sh with the following
    * Moved the rest of the header outputs to the /app/header.sh file
    * Updated both the service start and rsyslog services to point to /dev/null
    * Removed console clear because it's not clearing out the console logs
* Updated the /app/header.sh file with the rest of the header outputs
* Added new /app/output.sh file which has a console log output function for proper logging
* Added new changelog.md file to track any changelogs
* Added new README.md file to display project information and usages
* Updated the docker-compose.yml file with minor changes i.e. adding comments for line 20
* Updated the Dockerfile with the following
    * Removed the logo LABEL
    * Added maintainer LABEL
    * Added description LABEL
    * Added url LABEL
    * Added license LABEL
    * Updated ENV RUNLEVEL 1 to be ENV RUNLEVEL=1 as part of the Docker standard
    * Consolidated RUN commands to reduce unnecessary layers

## Version 0.1 - 0.2 (Sat, Aug 31 2024)
* Initial release