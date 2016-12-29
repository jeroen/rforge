# sudo apt-get install subversion git-svn curl
Sys.setenv(GITHUB_PAT = "xxxxxxxxxxxxxxxxx")

# For scraping repositories
# library(rvest)

sys <- function(name, args){
  res <- system2(name, args)
  if(res != 0)
    stop(sprintf("Command failed: %s, %s", name, paste(args, collapse = " ")))
}

github_pat <- function () {
  pat <- Sys.getenv("GITHUB_PAT", unset = NA)
  if(is.na(pat))
    stop("Need to set GITHUB_PAT")
  return(pat)
}

find_pages <- function(){
  main <- xml2::read_html("https://r-forge.r-project.org/softwaremap/full_list.php?page=0")
  links <- rvest::html_nodes(main, 'a[href^="/softwaremap/full_list.php?page="]')
  paste0("https://r-forge.r-project.org/", unique(rvest::html_attr(links, "href")))
}

find_projects <- function(page){
  main <- xml2::read_html(page)
  links <- rvest::html_nodes(main, 'a[href^="https://r-forge.r-project.org/projects/"]')
  cat(sprintf("Found %d projects in %s\n", length(links), basename(page)))
  rvest::html_attr(links, "href")  
}

find_all_projects <- function(){
  pages <- find_pages()
  projects <- lapply(pages, find_projects)
  sort(basename(unlist(projects)))
}

gh <- function(){
  httr::add_headers("Authorization" = paste("token", github_pat()))
}

make_repo <- function(project){
  req <- httr::GET(sprintf("https://api.github.com/repos/rforge/%s", project), gh())
  if(req$status_code == 404){
    payload <- list(
      name = project,
      has_issues = FALSE,
      has_wiki = FALSE,
      has_downloads = FALSE,
      homepage = paste0("https://r-forge.r-project.org/projects/", project),
      description = sprintf("Read-only mirror of \"%s\" from r-forge SVN.", project)
    )
    req <- httr::POST("https://api.github.com/user/repos", body = payload, encode = "json", gh())
    httr::stop_for_status(req)
    req <- httr::GET(sprintf("https://api.github.com/repos/rforge/%s", project), gh())
  }
  httr::stop_for_status(req)
}

sync_repo <- function(project){
  #Sys.setenv(GIT_SSH_COMMAND = "ssh -oStrictHostKeyChecking=no -i ~/rforge/rforge.key")
  olddir <- getwd()
  on.exit(setwd(olddir))
  sys("git", c("svn", "clone", sprintf("svn://svn.r-forge.r-project.org/svnroot/%s", project), project))
  setwd(project)
  sys("git", c("remote", "add", "origin", sprintf("https://rforge:%s@github.com/rforge/%s.git", github_pat(), project)))
  sys("git", c("push", "-f", "origin", "--mirror"))
  setwd("..")
  unlink(project, recursive = TRUE)
}

sync_all <- function(){
  logfile <- file("sync.log", open = "at")
  on.exit(close(logfile))
  writeLines(sprintf("START FULL SYNC AT: %s", as.character(Sys.time())), con = logfile)
  setwd(tempdir())
  repos <- find_all_projects()
  lapply(repos, function(project){
    out <- try({
      make_repo(project);
      sync_repo(project);
    })
    if(inherits(out, "try-error")){
      writeLines(sprintf("error: %s - %s", project, as.character(out)), con = logfile)
    } else {
      writeLines(sprintf("success: %s", project), con = logfile)
    }
    flush(logfile)
  })
  writeLines(sprintf("DONE AT: %s", as.character(Sys.time())), con = logfile)
}

## Cleaning old repos
list_repos <- function(){
  req <- httr::GET("https://api.github.com/users/rforge", gh())
  httr::stop_for_status(req)
  total <- httr::content(req, "parsed")$public_repos
  pages <- ceiling(total / 100)
  repos <- character()
  for(i in seq_len(pages)){
    req <- httr::GET(paste0("https://api.github.com/user/repos?per_page=100&page=", i), gh())
    httr::stop_for_status(req)
    data <- httr::content(req, "parsed", simplifyVector = TRUE)
    repos <- c(repos, data$name)
    cat("success at page", i, "\n")
  }
  sort(repos)
}

clean_repos <- function(){
  lapply(list_repos(), function(project){
    req <- httr::GET(sprintf("https://r-forge.r-project.org/projects/%s/", project))
    httr::stop_for_status(req)
    text <- httr::content(req, "text")
    if(grepl("Permission denied. No project was chosen", text)){
      req <- httr::DELETE(sprintf("https://api.github.com/repos/rforge/%s", project), gh())
      httr::stop_for_status(req)
      cat(sprintf("DELETED: %s\n", project))
    } else {
      cat(sprintf("OK: %s\n", project))
    }
  })
}

##RUN
sync_all()
clean_repos()