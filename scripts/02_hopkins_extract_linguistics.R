# ==============================================================================================================================================================
# DementiaBank English PPA Hopkins Corpus | 02_hopkins_extract_linguistics.R
# Data Extraction: Linguistic Features for PPA Variant (nfvPPA, lvPPA, svPPA) Classification
# ==============================================================================================================================================================

# 1. Load Packages 
library(tidyverse) # Gives pipe operator (%>%), map_dfr() to process files, and write_csv for preparing csv file
library(stringr) # Search and detect text patterns
library(fs) # Helps R find file paths to ensure tidyverse compatibility
library(udpipe) # Reads text and labels words as nouns, verbs, adjectives (Part of speech tagging)

# 2. File Paths
raw_cha_dir <- "data/hopkins_cha" # Show R where data is
output_dir  <- "outputs" # Show R where to store extracted features in the end

# 3. Load the English NLP model for Part of Speech (nouns,verbs, and adjectives) tagging
  ud_model <- udpipe_load_model("NLP_POS_model/english-ewt-ud-2.5-191206.udpipe")

# 4. Identify, read, and extract .cha files
cha_files <- dir_ls(raw_cha_dir, glob = "*.cha") # Make a list of all .cha files

message(paste("Found", length(cha_files), "file(s). Processing PPA features...")) # Displays how many .cha files found - need to find 50

# Extract features from one .cha file at a time
extract_ppa_features <- function(file_path) {
  
  pid <- path_ext_remove(path_file(file_path)) # Get patient ID by removing .cha to file name
  raw_lines <- readLines(file_path, warn = FALSE, encoding = "UTF-8") # Read transcripts line by line in R
  
  # Step A: Extract Participant Lines by identifying and isolating *PAR:
  # Done because .cha files also have dialogues from clinicians and others
  par_lines <- c() # Creates empty list to store patient's lines
  is_par_block <- FALSE # Toogle switch to FALSE to tell R that we are NOT reading patient speech right now
  
  # Loops through the raw file line by line
  for (line in raw_lines) {
    # If line starts with PAR:...
    if (str_detect(line, "^\\*PAR:")) {
      # Toggle switch to TRUE to tell R we ARE reading patient speech now
      is_par_block <- TRUE
      # Removes PAR: tag to keep text only
      par_lines <- c(par_lines, str_replace(line, "^\\*PAR:\\s*", ""))
      # If the switch is TRUE and the line starts with a tab key (\t)...
    } else if (is_par_block && str_detect(line, "^\\t")) {
      # It means the patient's sentence extended into a new line so attach it to the previous line
      par_lines[length(par_lines)] <- paste(par_lines[length(par_lines)], str_trim(line))
      # If the line starts with INV: (clinician) or metadata (@)...
    } else if (str_detect(line, "^\\*|^@")) {
      # Flip the switch back to FALSE to tell R we are NOT reading anymore because this isn't the patient
      is_par_block <- FALSE
    }
  }
  
  num_utterances <- length(par_lines) # Counts total sentences patient spoke in transcript
  
  # Step B: Count Pauses and Fillers BEFORE text cleaning so they don't get erased
  # .cha pauses include (.), (..), (...), and fillers include um, uh
  pause_count <- sum(str_count(par_lines, "\\(\\.\\.\\.\\)|\\(\\.\\.\\)|\\(\\.\\)")) # Pause count
  filler_count <- sum(str_count(par_lines, "&-[a-zA-Z]+")) # Hesitation Word Count
  
  # Step C: Clean and Prepare Text for NLP Analysis
  clean_lines <- par_lines %>%
    str_replace_all("\x15\\d+_\\d+\x15", "") %>%  # Remove audio timestamps
    str_replace_all("&-[a-zA-Z]+", "")         %>%  # Remove pauses and fillers
    str_replace_all("&=[^\\s]+", "")          %>%  # Remove non-word actions like coughing, laughing
    str_replace_all("\\[.*?\\]", "")          %>%  # Remove annotations and comments
    str_replace_all("[^a-zA-Z'\\s]", "")      %>%  # Remove punctuation, numbers, and symbols
    str_squish() # Cuts blank spaces at edges and trims to one space between words    
  
  full_transcript <- paste(clean_lines[clean_lines != ""], collapse = " ") # Organizes pure text into text string
  
  
  # Step D: NLP Part of Speech Tagging using UDPipe
  annotated_text <- udpipe_annotate(ud_model, x = full_transcript) # Sends text string for POS tagging
  nlp_df <- as.data.frame(annotated_text) # Convert into data frame so can easily use functions like 'filter()' and 'sum()' to count nouns, verbs, and adjectives
  
  # Before Step E: Filter out punctuation and spaces so only words remain
  # Done to ensure a safety net just in case UDPipe's Neural Network model created tokens for symbols and spaces
  tokens_df <- nlp_df %>% filter(!upos %in% c("PUNCT", "SYM", "X", "SPACE"))
  
  # Step E: Calculate Linguistic Metrics
  total_words  <- nrow(tokens_df) # Total token count = total words spoken by patient
  unique_words <- length(unique(tolower(tokens_df$lemma))) # Vocabulary diversity based on root lemmas = count of unique root words used
  
  # 1. Lexical Metrics
  mlu <- total_words / num_utterances # Mean Length of Utterance = average number of words per sentence
  ttr <- unique_words / total_words # Type Token Ratio = how many of total words are unique
  
  # 2. Part of Speech
  # 2A. POS Counts
  noun_count <- sum(tokens_df$upos %in% c("NOUN", "PROPN")) # Number of Nouns and Proper Nouns
  verb_count <- sum(tokens_df$upos == "VERB") # Number of Verbs
  adj_count  <- sum(tokens_df$upos == "ADJ") # Number of Adjectives
  
  # 2B. Group POS counts into Closed Class (Grammatical) or Open Class (Content)
  # Closed = Pronouns, Prepositions, Conjunctions, Auxiliary verbs, Determiners; Make sentences connect and flow smoothly
  # Open = Nouns, Proper nouns, Verbs, Adjectives, Adverbs; Building blocks of sentences
  closed_class_count <- sum(tokens_df$upos %in% c("PRON", "ADP", "CCONJ", "SCONJ", "AUX", "DET"))
  open_class_count   <- sum(tokens_df$upos %in% c("NOUN", "PROPN", "VERB", "ADJ", "ADV"))
  
  # 3. Diagnostic Ratios
  # +0.001 added to denominators to prevent division by zero errors if patient speaks 0 words of denominator category
  noun_verb_ratio    <- noun_count / (verb_count + 0.001) # Measures if patient struggles with nouns (low ratio) or verbs (high ratio)
  closed_open_ratio  <- closed_class_count / (open_class_count + 0.001) # Measures if patient struggles with grammar (low ratio)
  pause_rate_per_utt <- pause_count / num_utterances # Measures how often silent pauses (....) occur
  filler_rate_per_utt<- filler_count / num_utterances # Measures how often filler pauses (um, uh) occur
  
  # Step F: Organizes all calculated metrics into clean data table with patient ID
  tibble(
    patient_id          = pid,
    total_utterances    = num_utterances,
    total_words         = total_words,
    unique_words        = unique_words,
    mlu                 = round(mlu, 3), # Round to three decimal places
    ttr                 = round(ttr, 3), # Round to three decimal places
    noun_count          = noun_count,
    verb_count          = verb_count,
    adj_count           = adj_count,
    noun_verb_ratio     = round(noun_verb_ratio, 3),# Round to three decimal places
    closed_class_count  = closed_class_count,
    open_class_count    = open_class_count,
    closed_open_ratio   = round(closed_open_ratio, 3),# Round to three decimal places
    pause_count         = pause_count,
    filler_count        = filler_count,
    pause_rate_per_utt  = round(pause_rate_per_utt, 3), # Round to three decimal places
    filler_rate_per_utt = round(filler_rate_per_utt, 3) # Round to three decimal places
  )
}

# 5. Run Extraction across all .cha files
ppa_linguistic_data <- map_dfr(cha_files, extract_ppa_features) # Takes all .cha files and runs extraction function one by one to build a master data table

# 6. Save as CSV file in outputs folder
output_file <- path(output_dir, "ppa_hopkins_linguistic_features.csv") # file destination path
write_csv(ppa_linguistic_data, output_file) # Writes file as CSV

# Helpful messages to signal that extraction is done and saved in outputs folder as instructed
message("\n EXTRACTION COMPLETE!")
message(paste("Saved", nrow(ppa_linguistic_data), "patient records to:", output_file))

# Inspect data by displaying first few rows
print(head(ppa_linguistic_data))