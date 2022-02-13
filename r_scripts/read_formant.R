library(tidyverse)

read_formant <- function(datapath){
  #import the original dataset
  formant <- read_delim(datapath, delim = "\t", col_types = cols(
    Seg = col_factor(),
    Syll = col_factor(),
    Seg_num = col_character()
  )) %>% 
    rename(Tone = Syll) %>%
    select(-X15)
  
  #Return the dataset as the function output
  return(formant)
}
