##### Declaring Functions ########
strToDf <- function(string, columnsToProduce = 2, columnNames = c("Code", "Name")){
  stringDf = tibble(Values = string) %>% 
    mutate(Categories = rep(1:columnsToProduce, (nrow(.)/columnsToProduce))) %>% 
    mutate(Groupings = rep(1:(nrow(.)/columnsToProduce), each = columnsToProduce)) %>% 
    spread(Categories, Values ) %>% 
    select(-Groupings) %>% 
    set_names(columnNames)
  
  return(stringDf)
}

CIConnexName <- function(x){
  return(
    colleges %>% 
      filter(grepl(x, institution_name, ignore.case = T))
  )
}

#Checking to see if programs exists and removing if so
remove_old_programs <- function(url, object = NA){
  objs = ls(pos = ".GlobalEnv")
  if(url == 1){
    print(paste("Removed", objs[grep(paste0("^programs$|^Fees$|^program_url_collections$|^", object, "$"), objs)]))
    rm(list = objs[grep(paste0("^programs$|^Fees$|^program_url_collections$|^", object, "$"), objs)], pos = ".GlobalEnv")
  }
}


### scraping helper functions

get_urls <- function(class, url){
  
  read_html(url) %>% 
    html_nodes(class) %>% 
    html_nodes("a") %>% 
    html_attr("href")
}


possibleError <- function(url){
  
  Error = tryCatch(
    read_html(url),
    error = function(e) e
  )
  
  return(Error)
}

possibleErrorRselenium <- function(xpath){
  
  Error = tryCatch(
    remDr$findElement(using = 'xpath', xpath),
    error = function(e) e
  )
  
  return(Error)
}

possibleSelError <- function(remDr, xpath){
  
  Error = tryCatch(
    remDr$findElement(using = "xpath", xpath),
    error = function(e) e
  )
  
  return(Error)
}

replace_empty_na <- function(variable){
  if(length(variable) < 1){
    detail = NA
  } else {
    detail = variable
  }
  return(detail)
}

clean_tags <- function(stringVar){
  return(gsub("^[[:blank:]]+", "", gsub("[[:blank:]]{2,}", " ", gsub("\r|\n|\t", "", stringVar))))
}

clean_css_space <- function(stringVar) {
  return(gsub("[[:space:]]+", ".", stringVar))
}

# key workhorse - reads in html structure
read_webPage <- function(url){
  
  if(!inherits(possibleError(url), "error")){
    webPage = read_html(url)
    return(webPage)
  }
}


get_element <- function(xpath){
  
  if(!inherits(possibleErrorRselenium(xpath), "error")){
    element = remDr$findElement(using = 'xpath', xpath)
    return(element)
  }
}

# key workhorse - gets text from specific class in html structure
get_details <- function(webPage, class, urlGrab = F){
  
  if(urlGrab == F){
    detail = webPage %>% 
      html_nodes(class) %>% 
      html_text()
    
    detail = sapply(detail, function(x) clean_tags(x))
  } else {
    detail = webPage %>% 
      html_nodes(class) %>% 
      html_attr("href")
  }
  
  return(detail)
  
}

get_details_xpath <- function(webPage, xpath, urlGrab = F){
  
  if(urlGrab == F){
    detail = webPage %>% 
      html_nodes(xpath = xpath) %>% 
      html_text()
    
    detail = sapply(detail, function(x) clean_tags(x))
  } else {
    detail = webPage %>% 
      html_nodes(xpath = xpath) %>% 
      html_attr("href")
  }
  
  return(detail)
  
}

# key workhorse - gets table from specific class in html structure
get_details_table <- function(webPage, class = NA, xpath = NA){
  if(is.na(xpath)){
    detail = webPage %>% 
      html_nodes(class) %>% 
      html_table(fill = T)
    return(detail)
  } else if(is.na(class)) {
    detail = webPage %>% 
      html_nodes(xpath = xpath) %>% 
      html_table(fill = T)
    return(detail)
  }
}

## key workhorse - gets table from specific class in html structure
#get_details_table_xpath <- function(webPage, xpath){
#  detail = webPage %>% 
#    html_nodes(xpath = xpath) %>% 
#    html_table(fill = T)
#  return(detail)
#}

get_details_id <- function(webPage, id, class = NA, class_before = T){
  if(class_before == T){
    if(is.na(class)){
      detail = webPage %>% 
        html_nodes(xpath = paste0('//*[@id="', id, '"]')) %>% 
        html_text()
    } else {
      detail = webPage %>% 
        html_nodes(class) %>% 
        html_nodes(xpath = paste0('//*[@id="', id, '"]')) %>% 
        html_text()
      
    }
  } else {
    if(is.na(class)){
      detail = webPage %>% 
        html_nodes(xpath = paste0('//*[@id="', id, '"]')) %>% 
        html_text()
    } else {
      detail = webPage %>% 
        html_nodes(xpath = paste0('//*[@id="', id, '"]')) %>% 
        html_nodes(class) %>% 
        html_text()
      
    }
  }

  
  detail = sapply(detail, function(x) clean_tags(x))
  
  return(detail)
}



get_details_id_table <- function(webPage, id, class = NA, class_before = T){
  if(class_before == T){
    if(is.na(class)){
      detail = webPage %>% 
        html_nodes(xpath = paste0('//*[@id="', id, '"]')) %>% 
        html_table()
    } else {
      detail = webPage %>% 
        html_nodes(class) %>% 
        html_nodes(xpath = paste0('//*[@id="', id, '"]')) %>% 
        html_table()
      
    }
  } else {
    if(is.na(class)){
      detail = webPage %>% 
        html_nodes(xpath = paste0('//*[@id="', id, '"]')) %>% 
        html_table()
    } else {
      detail = webPage %>% 
        html_nodes(xpath = paste0('//*[@id="', id, '"]')) %>% 
        html_nodes(class) %>% 
        html_table()
      
    }
  }
  
  
  detail = sapply(detail, function(x) clean_tags(x))
  
  return(detail)
}

## using regex search through first set of texts to find a specific node within nodes
# Use only if there is no other tag to go by
# add 3rd class if you want to go one step deeper
get_details_index <- function(webPage, searchString, class_1, class_2, class_3 = NA, urlGrab = F, index_offset = 0, use_last_position = F){
  #Finding text to search for searchString using class_1
  index = webPage %>% 
    html_nodes(class_1) %>% 
    html_text()
  #print(index)
  
  #Finding position of searchString in the text
  index = grep(searchString, index, ignore.case = T)
  #print(index)  
  
  #if index_offset is given, adjusting index_offset here
  index = index + index_offset
  #print(index)

  #Finding details text - text where the actual information is stored
  detail = webPage %>% 
    html_nodes(class_2)
  

  
  #Moving on to isolating the desired details from above object "detail"
  if(length(index) > 0){
    
    #if use_last_position is true overwrite index
    if(use_last_position == T){
      if(index > length(detail)){
        print(index)
        print(length(detail))
        index = length(detail)
      }
    }
    
    
    if(urlGrab == F) {
      
      #If only searching a simple one layer down css grab
      if(is.na(class_3)){
        #print("No class_3 given")
        detail = detail[index] %>% 
          html_text()
        

        
        detail = sapply(detail, function(x) clean_tags(x))
        return(detail)
      } else {
        #print("Class_3 given")
        #print(detail[index])
        #If using a class further down
        detail = detail[index] %>% 
          html_nodes(class_3) %>% 
          html_text()
        
        
        detail = sapply(detail, function(x) clean_tags(x))
        return(detail)
      }
    }
    
    if(urlGrab == T) {
      if(is.na(class_3)){
        detail = detail[index] %>% 
          html_attr("href")
        
        return(detail)
      } else {
        detail = detail[index] %>% 
          html_nodes(class_3) %>% 
          html_attr("href")
        
        return(detail)
      }
    }
    
  }
  
  return(NA)
}


#Simpler version of above
get_details_str_split <- function(webPage, searchString = "", splitString = "", ignoreCase =F, offset = 0){
  detail = webPage %>% html_text() %>% str_split(splitString) %>% unlist()
  detail = detail[grep(searchString, detail, ignore.case = ignoreCase) + offset]
  return(detail)
  
}



get_details_for_filtering <- function(webPage, class, split_on = "\n"){
  return(webPage %>% 
           html_nodes(class) %>% 
           html_text() %>% 
           strsplit(split_on) %>% 
           unlist())
}


get_detail_df <- function(detail_df, category = "", separation = " "){
  names(detail_df) <- c("Category", "Detail")
  return(detail_df %>% filter(grepl(category, Category, ignore.case = T)) %>% select(Detail) %>% unlist() %>% clean_tags() %>% paste(., collapse = separation))
}


get_detail_id <- function(webPage, id = "", attribute = 'id'){
  div_ids <- webPage %>%  html_attr(attribute)
  
  detail = webPage[grepl(id, div_ids)] 
  return(detail)
  
}


#Function for finding button to click, then finding subsequently revealed data using RSelenium variable
find_and_click <- function(remDr, clickPath, dataPath, pause = .75){
  
  
  if(!inherits(possibleSelError(remDr, clicPath), "error")){
    webElem <- remDr$findElement(using = "xpath", clickPath)
    Sys.sleep(pause)
    webElem$clickElement()
    Sys.sleep(pause)
    
    if(!inherits(possibleSelError(remDr, dataPath), "error")){
      errorCheck = possibleSelError(remDr, dataPath)
      returnData <- remDr$findElement(using = "xpath", dataPath)
      return(returnData)
    } else {
      return(NA)
    }
    
  }else {
    return(NA)
  }
  
}

# key workhorse - combines class names and class content (if structured differently)
combine_details <- function(webPage, class_names, class_content){
  names = get_details(webPage, class_names)
  content = get_details(webPage, class_content)
  
  detailDf = tibble(names = names,
                    content = content) %>% 
    spread(names, content)
  
  return(detailDf)
}


create_program_df <- function(Institution, url = NA, Program = NA, Credential = NA, Campus = NA, Duration = NA, Description = NA, WIL = NA){

  program = tibble(institution_name = Institution$institution_name,
                   url = url, 
                   Program = Program, 
                   Credential = Credential %>% replace_empty_na(), 
                   Campus = Campus %>% replace_empty_na(), 
                   Duration = Duration %>% replace_empty_na(), 
                   Description = Description %>% replace_empty_na(), 
                   WIL = WIL %>% replace_empty_na())

  program = Institution %>% 
    left_join(program,
              by = "institution_name")
  
  return(program)
}

get_courses <- function(url, isTable = T, tableContClass){
  if(!is.na(url)){
    #reading in web page structure
    webPage = read_webPage(url)
    
    #checking to see if web structure includes the table tag
    includesTable = webPage %>% grepl("<table", .)
    #print(includesTable)
    if(isTable == T & includesTable == T){
      courses = webPage %>% 
        html_nodes(tableContClass) %>%
        html_nodes("table") %>% 
        html_table(fill = T) %>% 
        bind_rows() %>% 
        as_tibble() 
      
      #Returning data frame (tibble)
      return(courses)
    } else {
      courses = tibble()
    }
  } else {
    courses = tibble()
  }
}

clean_string <- function(stringVar){
  return(gsub(" |/", "_", gsub('\\"|\n|\\(|\\)|&|-|\\*|\t|,|:', "", stringVar)))
}

get_detail_from_table <- function(table, searchColumn = "", detailColumn = "", searchTerm = ""){
  return(table %>% select(c(searchColumn, detailColumn)) %>%  filter(grepl(searchTerm, !!sym(searchColumn), ignore.case = T)) %>% distinct() %>% summarize(detail = paste(!!sym(detailColumn), collapse = " AND "))) %>% select(detail) %>% unlist()
}
  
  
get_detail_node_table <- function(webPage){
  return(tibble(nodeName = webPage %>% html_name(),
                nodeText = webPage %>% html_text()))
}  


get_details_from_node_table <- function(node_table, nodeType_filter = "", nodeText_filter = ""){
  node_table %>% 
    mutate(section = zoo::na.locf(ifelse(grepl(nodeType_filter, nodeName), nodeText, NA), na.rm = F)) %>% 
    filter(grepl(nodeText_filter, section)) %>% 
    filter(nodeName != nodeType_filter) %>% 
    select(nodeText) %>% 
    unlist() %>% 
    paste(., collapse = " ")
}

##### This is the shakiest funciton - getting course data
course_eval <- function(courses, Institution, Program, Program_url, noDescription = T, FR = F){
  
  if(noDescription == T){
    course_df = courses %>% 
      mutate(Institution = Institution,
             Program = Program,
             Program_url = Program_url,
             Description = NA) %>% 
      select(Institution, Program, Program_url, Code, Name, Description)
  } else {
    course_df = courses %>% 
      mutate(Institution = Institution,
             Program = Program,
             Program_url = Program_url) %>% 
      select(Institution, Program, Program_url, Code, Name, Description)
  }
  

  
  dir.create(paste0("courses/", clean_string(Institution)), showWarnings = FALSE)
  progFileName <- gsub(" |/|_2,}", "_", gsub('\\"|\n|\\(|\\)|&|-|\\*|\t|,|:', "", Program))
  if(nchar(progFileName) > 50){
    progFileName <- substr(progFileName,1,50)
  }
  write.csv(course_df, paste0("courses/", clean_string(Institution), "/", progFileName, ".csv"))
  if(FR == F){
    WIL <- course_df$Name[grepl("Pratique|Practicum|Field placement|Placement|Work experience|Co-op|coop|Apprentice|internship|field practice|clinical practice|clinical work|work term| stage |^wil |^wil$|capstone", course_df$Name, ignore.case = T)]  
  }else {
    WIL <- course_df$Name[grepl(" stage ", course_df$Name, ignore.case = T)]  
  }
  
  
  if(length(WIL) > 0){
    #print(paste(WIL, collapse = " AND "))
    return(paste(WIL, collapse = " AND "))
  } else {
    return(NA)
  }
}



save_out_standard_file <- function(programs, Institution, region){
  region_check = grepl(region, paste(list.dirs("programs"), collapse = ","))
  if(region_check == F){
    dir.create(paste0("programs/", region))
    dir.create(paste0("programs/", region, "/Archive"))
  }
  
  programs = programs %>% 
    select(institution_name, prov_terr, record_id, member, url, Program, Credential, Campus, Duration, Description, WIL) %>% 
    distinct()
  
  old_files = list.files(paste0("programs/",region))
  old_files = if(length(old_files) > 1) old_files[grepl(clean_string(Institution), old_files)]
  
  if(length(old_files) > 0){
    file.copy(paste0("programs/",region, "/",old_files), paste0("programs/",region, "/Archive/",old_files))
    file.remove(paste0("programs/",region, "/",old_files))
  }
  
  write_rds(programs, paste0("programs/",region, "/", clean_string(Institution),"_", Sys.Date(),  "_programs.rds"))
  write_csv(programs, paste0("programs/",region, "/", clean_string(Institution),"_", Sys.Date(),  "_programs.csv"), na = "")
  if(exists("Fees")){
    write_rds(programs, paste0("programs/",region, "/", clean_string(Institution),"_", Sys.Date(),  "_fees.rds"))
    
  }
}

### End data handling helper functions
