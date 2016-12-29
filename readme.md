# RForge Github Mirror

A script to sync the [rforge mirror](https://github.com/rforge) on Github. 

 1. Scrapes repo names from the rforge website
 2. For each repo: 
   - Initiate the Github repository if it does not exist yet
   - Clone from rforge svn and push to Github

## Installation

Requires the `git-svn` plugin and some R packages:

```sh
sudo apt-get install subversion git-svn r-base-dev libcurl4-openssl-dev libxml2-dev
```

Installing packages:

```r
# also installs: httr, xml2
install.packages("rvest")
```

## How to use

Set a Github PAT for user `rforge` in the first line of the script. Three functions:

 - `sync_all()` updates all repositories (except for the ones dead for 5+ years)
 - `sync_active()` updates repositories activity in the past week
 - `clean_repos()` deletes repos from Github that are no longer on rforge
 
Best is a daily CRON job with the latter two I think.

## To do

The current script deletes the repo after each sync because I ran out of disk space. Better is to keep the repo and sync it with:

```sh
git svn rebase 
git push origin master
```

Then again not sure I care enough.

