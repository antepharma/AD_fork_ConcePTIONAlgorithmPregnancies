##Retrieve from VISIT_OCCURRENCE_ID and from SURVEY_ID all the records that have the prompts listed in 04_prompts

#----------
# SURVEY_ID
#----------

if (this_datasource_has_prompt) {
  
  SURVEY_ID_BR <- data.table()
  files<-sub('\\.csv$', '', list.files(dirinput))
  
  for (i in 1:length(files)) {
    if (str_detect(files[i],"^SURVEY_ID")) {
      
      tmp <- fread(paste0(dirinput,files[i],".csv"), 
                   colClasses = list(character="person_id"))
      if(this_datasource_has_prompt_child){
        tmp <- tmp[survey_meaning %in% c(unlist(meaning_of_survey_pregnancy_this_datasource), 
                                         unlist(meaning_of_survey_pregnancy_this_datasource_child)),]
      }else{
        tmp <- tmp[survey_meaning %in% unlist(meaning_of_survey_pregnancy_this_datasource),]
      }
      
      
      SURVEY_ID_BR <-rbind(SURVEY_ID_BR, tmp)
    }
  }
  
  SURVEY_ID_BR<-SURVEY_ID_BR[,survey_date:=ymd(survey_date)]
  SURVEY_ID_BR<-unique(SURVEY_ID_BR, by=c("person_id","survey_id","survey_date"))
  
  #------------------------------------
  # Replace survey ID for child records
  #------------------------------------
  if(this_datasource_has_prompt_child){
    PERSON_RELATIONSHIPS <- fread(paste0(dirinput, "PERSON_RELATIONSHIPS.csv"), 
                                  colClasses = list(character=c("person_id", "related_id")))
    
    PERSON_RELATIONSHIPS_child <- PERSON_RELATIONSHIPS[meaning_of_relationship %in% meaning_of_relationship_child_this_datasource]
    
    if(this_datasource_has_related_id_correspondig_to_child){
      PERSON_RELATIONSHIPS_child <- PERSON_RELATIONSHIPS_child[, person_id_mother := person_id]
      PERSON_RELATIONSHIPS_child <- PERSON_RELATIONSHIPS_child[, person_id_child := related_id]
      PERSON_RELATIONSHIPS_child <- PERSON_RELATIONSHIPS_child[, -c("person_id", "related_id")]
      
      setnames(PERSON_RELATIONSHIPS_child, "person_id_mother", "related_id")
      setnames(PERSON_RELATIONSHIPS_child, "person_id_child", "person_id")
    }
    
    tmp <- merge(SURVEY_ID_BR,
                 PERSON_RELATIONSHIPS_child[, .(person_id, related_id)], 
                 by = "person_id", 
                 all.x = TRUE)
    
    SURVEY_ID_BR<-tmp[survey_meaning %in% unlist(meaning_of_survey_pregnancy_this_datasource_child),
                      person_id := related_id]
    
    SURVEY_ID_BR <- SURVEY_ID_BR[, -c("related_id")]
  }

  
  
  ##### Description #####
  if(HTML_files_creation){
    if(nrow(SURVEY_ID_BR)!=0){
      cat("Describing SURVEY_ID_BR \n")
      DescribeThisDataset(Dataset = SURVEY_ID_BR,
                          Individual=T,
                          ColumnN=NULL,
                          HeadOfDataset=FALSE,
                          StructureOfDataset=FALSE,
                          NameOutputFile="SURVEY_ID_BR",
                          Cols=list("survey_origin", "survey_meaning"),
                          ColsFormat=list("categorical", "categorical"),
                          DateFormat_ymd=FALSE,
                          DetailInformation=TRUE,
                          PathOutputFolder= dirdescribe01_prompts)
    }
  }

  save(SURVEY_ID_BR, file=paste0(dirtemp,"SURVEY_ID_BR.RData"))
  rm(SURVEY_ID_BR)
}

#--------------------
# VISIT_OCCURRENCE_ID 
#--------------------

if (this_datasource_has_visit_occurrence_prompt) {
  
  VISIT_OCCURRENCE_PREG <- data.table()
  files<-sub('\\.csv$', '', list.files(dirinput))
  
  for (i in 1:length(files)) {
    if (str_detect(files[i],"^VISIT_OCCURRENCE")) {
      
      tmp <- fread(paste0(dirinput,files[i],".csv"))
      tmp <- tmp[(meaning_of_visit %chin% unlist(meaning_of_visit_pregnancy_this_datasource)),]
      
      VISIT_OCCURRENCE_PREG <-rbind(VISIT_OCCURRENCE_PREG, tmp)
      
    }
  }
  
  ##### Description #####
  if(HTML_files_creation){
    cat("Describing VISIT_OCCURRENCE_PREG \n")
    DescribeThisDataset(Dataset = VISIT_OCCURRENCE_PREG,
                        Individual=T,
                        ColumnN=NULL,
                        HeadOfDataset=FALSE,
                        StructureOfDataset=FALSE,
                        NameOutputFile="VISIT_OCCURRENCE_PREG",
                        Cols=list("meaning_of_visit", "origin_of_visit"),
                        ColsFormat=list("categorical", "categorical"),
                        DateFormat_ymd=FALSE,
                        DetailInformation=TRUE,
                        PathOutputFolder= dirdescribe01_prompts)
  }
  
  save(VISIT_OCCURRENCE_PREG, file=paste0(dirtemp,"VISIT_OCCURRENCE_PREG.RData"))
  rm(VISIT_OCCURRENCE_PREG)
  
}


#-----------
# PERSON_REL
#-----------

if(this_datasource_has_person_rel_table){
  
  # Reading person_relationship table, filtering for meaning_of_relationship_child_this_datasource
  # and uniforming ids:
  #    person_id --> child
  #    related_id --> mother
  
  PERSON_RELATIONSHIPS <- fread(paste0(dirinput, "PERSON_RELATIONSHIPS.csv"), 
                                colClasses = list(character=c("person_id", "related_id")))
  
  PERSON_RELATIONSHIPS_child <- PERSON_RELATIONSHIPS[meaning_of_relationship %in% meaning_of_relationship_child_this_datasource]
  
  if(this_datasource_has_related_id_correspondig_to_child){
    PERSON_RELATIONSHIPS_child <- PERSON_RELATIONSHIPS_child[, person_id_mother := person_id]
    PERSON_RELATIONSHIPS_child <- PERSON_RELATIONSHIPS_child[, person_id_child := related_id]
    PERSON_RELATIONSHIPS_child <- PERSON_RELATIONSHIPS_child[, -c("person_id", "related_id")]
    
    setnames(PERSON_RELATIONSHIPS_child, "person_id_mother", "related_id")
    setnames(PERSON_RELATIONSHIPS_child, "person_id_child", "person_id")
  }
  
  # Loading D3_PERSONS and merging child's date of birth
  load(paste0(dirtemp, "D3_PERSONS.RData"))
  
  # uniforming date format
  D3_PERSONS[, day_of_birth := as.character(day_of_birth)]
  D3_PERSONS[nchar(day_of_birth) == 1, day_of_birth := paste0(0, day_of_birth)]
  
  D3_PERSONS[, month_of_birth := as.character(month_of_birth)]
  D3_PERSONS[nchar(month_of_birth) == 1, month_of_birth := paste0(0, month_of_birth)]
  
  D3_PERSONS[, birth_date := paste0(year_of_birth, month_of_birth, day_of_birth)]
  
  Person_rel_PROMPT_dataset <- merge(PERSON_RELATIONSHIPS_child, 
                                     D3_PERSONS[, .(person_id, birth_date)])
  
  # renaming ids
  setnames(Person_rel_PROMPT_dataset, "person_id", "child_id")
  setnames(Person_rel_PROMPT_dataset, "related_id", "person_id")
  
  ##### Description #####
  if(HTML_files_creation){
    cat("Describing Person_rel_PROMPT_dataset \n")
    DescribeThisDataset(Dataset = Person_rel_PROMPT_dataset,
                        Individual=T,
                        ColumnN=NULL,
                        HeadOfDataset=FALSE,
                        StructureOfDataset=FALSE,
                        NameOutputFile="Person_rel_PROMPT_dataset",
                        Cols=list("origin_of_relationship", "meaning_of_relationship"),
                        ColsFormat=list("categorical", "categorical"),
                        DateFormat_ymd=FALSE,
                        DetailInformation=TRUE,
                        PathOutputFolder= dirdescribe01_prompts)
  }
  
  save(Person_rel_PROMPT_dataset, file=paste0(dirtemp,"Person_rel_PROMPT_dataset.RData"))
  rm(Person_rel_PROMPT_dataset)
}