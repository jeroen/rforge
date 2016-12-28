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

Finally set a Github PAT for user `rforge` in the first line of the script.

## To do

The current script deletes the repo after each sync because I ran out of disk space. Better is to keep the repo and sync it with:

```sh
git svn rebase 
git push origin master
```

