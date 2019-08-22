# Makefile for this project
# by LINDAT/CLARIN dev team
#
# Note: If you want to change this file, copy it to project/config
# 

# lindat-common settings
DIR_LINDAT_COMMON_THEME :=/opt/lindat-common
URL_LINDAT_COMMON_GIT   :=https://github.com/ufal/lindat-common.git
LINDAT_COMMON_THEME_FETCH=git fetch && git checkout -f no-tracking-release && git pull

# tomcat
TOMCAT_VERSION=6
TOMCAT_USER:=developer
TOMCAT_GROUP:=developer
TOMCAT_CONF:=/etc/$(TOMCAT_USER)

# dspace
DSPACE_USER:=dspace

# tool directories
DIRECTORY_POSTGRESQL:=/var/lib/postgresql
BACKUP2l:=/usr/sbin/backup2l

# database settings - mostly for recovering 
#RESTORE_FROM_DATABASE=prod-dspace-1.8
RESTORE_FROM_DATABASE=lrt-dspace-1.8


# you can use different versions e.g., export pg_dump=pg_dump --cluster 9.4/main
export pg_dump=pg_dump
