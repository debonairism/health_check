#Health Checking
##This is a penetration test for the views health check pages (UNIX Based OS)

###Features:

    - The purpose is to check the views health page and return all the errors that are on the page
    - The script will ask you questions pertaining to which servers your would like to check
        - script will run the servers in parallel (current limitation set at: 4 processes)      
    
    JSON files that are not present in source control (but necessary):
        - health_check_url.json needs to present in the current directory to associate the correct URL's asked from prompt
        - health_check_rules.json needs to present to filter the services to be not present in the error output

###Installation Guide:
    
    - Download this repository 
    - Make sure that the first line of health_check.rb corresponds to the location of where ruby lives on your machine
        - if not, change to the path 
        - for most/usual installation of Ruby, the ENV of Ruby should be the correct
    - change permission of the health_check.rb file to be executable 
    - run "bundle install" from this directory to install all dependencies 
        - if you dont have bundle, run this command "gem install bundler" to install bundler


###Core Bump 0.1 --> 0.2

    - CHANGELOG: 
        - Added Gemfile to include dependencies 
        - Added service name to the error page
        - Added retry if page returns 404 error
        - Added options to pass the URL directly from the script

###Core Bump 0.2  --> 0.2.1
    
    - CHANGELOG:
        - Added in log that will clear in 30 days (health_check.log)       
        - Pass in any arguments and it will run all and exit the script
        
    
###Features to come  
  
    - Re-structuring repository
        - maybe package into a gem 
    - TDD
        - Rspec, Cucumber and friends 
    - Refactoring
        - Lots need to be done
    
####Version:
Beta - Version 0.2.1
