library(rvest)
library(tidytext)
library(dplyr)
library(RSelenium)

rd <- rsDriver()
remDr <- rd[["client"]]
remDr$navigate("https://twitter.com/PattyMurray")

#scraping_twitter <- read_html("https://twitter.com/realDonaldTrump")

#scroll down 5 times, waiting for the page to load at each time
for(i in 1:15){      
  remDr$executeScript(paste("scroll(0,",i*10000,");"))
  Sys.sleep(3)    
}

#get the page html
page_source<-remDr$getPageSource()

scraping_twitter <- read_html(page_source[[1]])

# Scrape all of the tweet content
tweets <- scraping_twitter %>% html_nodes(".tweet-text") %>% html_text()
tweets_df <- data_frame(lines = 1:length(tweets), text = tweets )

# Scrape all of the headers so we can limit the tweets to just a specific individual
headers <- scraping_twitter %>% html_nodes(".stream-item-header") %>% html_text()
headers_df <- data_frame(lines = 1:length(headers), text = headers)

# Combine it all together
content <- headers_df %>% inner_join(tweets_df, by = "lines")
colnames(content) <- c("lines", "header", "text")

# Subset data to filter out retweets
originals <- content %>% filter(stringr::str_detect(header, "@PattyMurray"))
# At this point, there are still pictures and links to videos (including titles) that will need to be filtered out

# Start the actual text analysis stuff
tokens <- originals[,-2] %>% unnest_tokens(word, text)
# Lets remove some stop words
data("stop_words")
tokens <- tokens %>% anti_join(stop_words)
# Lets count the most often used words
counts <- tokens %>% count(word, sort = TRUE)
