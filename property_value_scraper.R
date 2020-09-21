rm(list = ls()) # clear console
options(scipen = 999) # forces R to avoid exponential notation
system.info <- Sys.info()
setwd("/")


# install docker on linux
# tutorial: https://docs.ropensci.org/RSelenium/articles/docker.html
# Note: In the above tutorial I had to replace "sudo apt-get install -y docker-engine" 
# with "sudo apt-get install docker.io""


# load libraries ---------------------------------------------------------------
library(RSelenium)
library(stringr)
library(rvest)
library(httr)
library(tidyverse)

# start up docker: run these commands in the terminal if docker isn't already running :
    # sudo service docker start
    # sudo docker run -d -p 4445:4444 selenium/standalone-firefox:2.53.0

# start up selenium
ipv4 <- "" # input your ipv4 address
remDr <- remoteDriver(
  remoteServerAddr = ipv4,
  port = 4445L
)
remDr$open()  ## open the connection 

# give it a test run
remDr$navigate("https://www.google.com/")
remDr$getCurrentUrl() # view current url
#remDr$screenshot(display = TRUE) # display screenshot


# load in the list of addresses that need tax assesed values
addresses <- read_csv("addresses.csv")

# initialize a colum to store scraped tax assesor data
addresses$land_value <- NA
addresses$total_value <- NA

# loop through each address, search for it on the tax assesors website, and grap assessed value.
for(k in 1:nrow(addresses)){#loop will start here
  print(k)
  
    tryCatch({  # wrap loop in a trycatch statement so loop will move on to next observation if it encounters an error
      
      remDr$setImplicitWaitTimeout(milliseconds = 2000)  ## set a wait time for opperation (neccesary to give page elements time to load)
      
      # seperate street number and street name
      address_split <- str_split(addresses$Address[k]," ")[[1]]
      len <- length(address_split)
      street_number <- address_split[1]
      street <- paste(address_split[2:len], collapse = " ")
      
      # navigate to tax assesors website
      remDr$navigate("https://sdat.dat.maryland.gov/RealProperty/Pages/default.aspx")
      remDr$screenshot(display = T)
      
      # wait random amount of time between 1 and 5 seconds
      Sys.sleep(runif(1,1,5))
      
      # populate the dropdown menus
        # get element corresponding to worcester county
          county_dropdown <- remDr$findElement(using = 'xpath', "/html/body/form/div[3]/div[2]/div[4]/div/div/div/div[2]/div/table/tbody/tr[1]/td/div/div/fieldset/div[1]/div[2]/select/option[25]")
        # click the element
          county_dropdown$clickElement()
          
          # wait random amount of time between 1 and 5 seconds
          Sys.sleep(runif(1,1,5))
          
        # check to make sure the field populated
          #remDr$screenshot(display = T)
        
          # wait random amount of time between 1 and 5 seconds
          Sys.sleep(runif(1,1,5))
          
        # get element corresponding to a street address search
          method_dropdown <- remDr$findElement(using = 'xpath', "/html/body/form/div[3]/div[2]/div[4]/div/div/div/div[2]/div/table/tbody/tr[1]/td/div/div/fieldset/div[2]/div[2]/select/option[2]")
        
        # click the element 
          method_dropdown$clickElement()
          
        # wait random amount of time between 1 and 5 seconds
          Sys.sleep(runif(1,1,5))  
          
        # check to make sure the field populated
          remDr$screenshot(display = T)
          
      # identify the element for the continue button
          continue <- remDr$findElement(using = 'xpath','/html/body/form/div[3]/div[2]/div[4]/div/div/div/div[2]/div/table/tbody/tr[2]/td/input')
      
      # click the continue button
          continue$clickElement()
      
      # wait random amount of time between 1 and 5 seconds
      Sys.sleep(runif(1,1,5))
          
      # enter the street number
          street_num <- remDr$findElement(using = 'xpath','/html/body/form/div[3]/div[2]/div[4]/div/div/div/div[2]/div/table/tbody/tr[1]/td/div/fieldset/div[1]/div[2]/input')
          street_num$sendKeysToElement(list(street_number)) 
          
          # enter the street name
          street_name <- remDr$findElement(using = 'xpath','/html/body/form/div[3]/div[2]/div[4]/div/div/div/div[2]/div/table/tbody/tr[1]/td/div/fieldset/div[2]/div[2]/input')
          street_name$sendKeysToElement(list(street)) 
     
      # wait random amount of time between 1 and 5 seconds
      Sys.sleep(runif(1,1,5))    
               
      # click the next button    
          next_button <- remDr$findElement(using = 'xpath','/html/body/form/div[3]/div[2]/div[4]/div/div/div/div[2]/div/table/tbody/tr[2]/td/input[3]')
          next_button$clickElement()
          
      # wait random amount of time between 1 and 5 seconds
      Sys.sleep(runif(1,1,5))    
          
      # scrape table containing assesed home value
          # get land value
          land <- remDr$findElement(using = 'xpath','/html/body/form/div[3]/div[2]/div[4]/div/div/div/div[2]/div/table/tbody/tr[1]/td/div[3]/div[2]/table/tbody/tr/td/table[2]/tbody/tr[15]/td/table/tbody/tr[3]/td[2]/span')
          land <- str_split(land$getElementText()[[1]],"\n")[[1]]
     
       # wait random amount of time between 1 and 5 seconds
      Sys.sleep(runif(1,1,5))
      
          # get total value
          total <- remDr$findElement(using = 'xpath','/html/body/form/div[3]/div[2]/div[4]/div/div/div/div[2]/div/table/tbody/tr[1]/td/div[3]/div[2]/table/tbody/tr/td/table[2]/tbody/tr[15]/td/table/tbody/tr[5]/td[2]/span')
          total <- str_split(total$getElementText()[[1]],"\n")[[1]]
          
      # add scraped values to data frame      
          addresses$land_value[k] <- as.numeric(gsub(",","",land))
          addresses$total_value[k]  <- as.numeric(gsub(",","",total))
          
    }, error = function(e){cat("ERROR :",conditionMessage(e), "\n")})
      
}


# write scraped data to a csv file
write_csv(addresses, "addresses_scraped.csv")
