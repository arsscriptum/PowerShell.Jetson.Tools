# PowerShell Text Parser and Data Extractor

I admit that the above definition is extremely vague and nebulous. I will explain how this tool as used and why it was created, this information is the best way to define the tool to you.

## **Use Case** : apt-get errors parsing and processing

I work on an embedded development board which runs a Ubuntu Linux distribution. It requires a lot of configuration steps each time I need to install a new toolchain version.
I did a ***very*** bad mistake that made every call to ```apt``` and ```apt-get``` fail with hundreds, if not thousands of error messages. After some research I'm fairly certain that the best way forward is to reinstall all the packages that are listed in the logs. I recently counted as much as 1,500+ packages and dependencies in the logs.

> Enter PowerShell.

Using PowerShell's string manipulation functions and regex tools is the best way to achieve my goal; which is to fix my machine configuration so I can use ```apt-get``` again.


## Step-by-step Operations and their Functions

1) ***Invoke-ParseErrorLogs*** : takes a path to a file with the command stdout / stderr logs and extract the packages names, returns an arraylist of the packages
1) ***Invoke-GenerateCodeFromLogs*** : takes a package list and create a bash script that aims to reinstall each and every packages while logging the errors if ant.

## Tests

Located in the  ```apt-get.errors.parser\data``` directory are data files for your convenience. 

1) To test the parsing functions while I made them and validate their output. 
2) You can use those data files to simulate the real output from ```apt-get```. 


