#Author: Kenneth McClean
#https://github.com/KenMcClean

#------------Authenticate against Jira using basic authentication------------
$login = Get-Credential
#Rather than hard-coding credentials or using a read-host, get the credentials using a proper credential prompt

$PlainUsername = $login.GetNetworkCredential().UserName
#Convert the resulting login name to a useable string

$PlainPassword = $login.GetNetworkCredential().Password
#Convert the resulting password to a useable string without exposing it during the script execution

$pair = ($PlainUsername+':'+$plainpassword)
#Turn the username and password strings into a pair that can be converted to base64

$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$basicAuthValue = "Basic $base64"
$headers = @{ Authorization = $basicAuthValue }
#Establish the credentials used to authenticate against JIRA

#------------Declare the initial Variables------------
$filterID = @()
$indexPosition = 0
#Pagination always starts at 0, we don't need to calculate that

#------------Calculate the limit of pagination index------------
$maxIndex = Invoke-webrequest -Uri "<Jira URL>/jira/secure/ManageFilters.jspa?filterView=search&Search=Search&filterView=search&searchName=&searchOwnerUserName=&searchShareType=any&projectShare=12711&roleShare=&groupShare=ENV_AP_JIRA_IIT_Internal_Staff_only&userShare=&pagingOffset=$indexPosition&sortAscending=true&sortColumn=name" -Method get -headers $headers
#Because we're not making a call against the API, we're not using invoke-rest method. Instead we need to parse the HTML that is returned

$maxIndex = $maxIndex.ParsedHtml.body.getElementsByTagName('div') | Where {$_.getAttributeNode('class').Value -eq 'pagination aui-item'}
#The page notes the total number of filters, and shows 20 filters per page

$maxIndex = $maxIndex.textcontent -replace '\s+',' ' | Select-Object -Unique
#The page actually shows the total number of filters twice per page, with a lot of extra whitespace, so let's ignore that

$maxIndex -match '(?<=of )(.*)(?= Next)'
#Grab the actual number of filters. It's the number between "of" and "next"

$maxPaginationRange = [math]::ceiling($matches[0] / 20)
#Finally, calculate the pagination range.  If the number isn't a whole number, we need to tell PowerShell to round UP, so that last partial page of results is captured.


#------------Start iterating through the pages of results------------
while($indexPosition -lt $maxPaginationRange){
$data = Invoke-webrequest -Uri "<Jira URL>/jira/secure/ManageFilters.jspa?filterView=search&Search=Search&filterView=search&searchName=&searchOwnerUserName=&searchShareType=any&projectShare=12711&roleShare=&groupShare=ENV_AP_JIRA_IIT_Internal_Staff_only&userShare=&pagingOffset=$indexPosition&sortAscending=true&sortColumn=name" -Method get -headers $headers
#call the pages of results

$filterID = $data.Links.id -like "filterlink*" -replace "filterlink_", ""
#Grab all the relevant link IDs (filter IDs), and remove extranous information


#------------Query the API for the filter name and JQL of each filter------------
foreach($id in $filterid){
$filterData = Invoke-restmethod -Uri "<Jira URL>/jira/rest/api/2/filter/$id" -Method get -headers $headers
#Finally we can go back to calling the API, using the filter ID that we just noted

"Filter name:"+$filterdata.name+"Filter JQL:"+$filterdata.jql | Out-File c:\data\Filterdata.txt -append

}

$indexPosition++

}


