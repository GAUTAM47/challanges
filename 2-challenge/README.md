Challenge #2

We need to write code that will query the meta data of an instance within AWS or Azure or GCP and provide a json formatted output. 
The choice of language and implementation is up to you.

Bonus Points
The code allows for a particular data key to be retrieved individually
Hints
·         Aws Documentation (https://docs.aws.amazon.com/)
·         Azure Documentation (https://docs.microsoft.com/en-us/azure/?product=featured)
·         Google Documentation (https://cloud.google.com/docs)


For this challenge 2, I have fetched virtual mechine meta data information using app registation in key vault.
That has been done via below ways;-
A. Register app (newapp) in Azure active directory
    1. Open Azure active directory 
    2. Open 'App registations'
    3. New registration 

B. Role assignment in Azure VM's access control (IAM)
    1. Open azure resource where I want to grant permission (to newapp)
    2. From access control management - add new role assignment
    3. assign reader role to newapp (registered app)