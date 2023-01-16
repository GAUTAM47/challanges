/*Challenge #2

We need to write code that will query the meta data of an instance within AWS or Azure or GCP and provide a json formatted output. 
The choice of language and implementation is up to you.

Bonus Points
The code allows for a particular data key to be retrieved individually
Hints
·         Aws Documentation (https://docs.aws.amazon.com/)
·         Azure Documentation (https://docs.microsoft.com/en-us/azure/?product=featured)
·         Google Documentation (https://cloud.google.com/docs)
*/

using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using Microsoft.Identity.Client;
using Microsoft.Json.Linq;
namespace AzureMetaData
{
    class Program
    {
        static async Task Main(string[] args)
        {
            // azure active directory tenant id
            string tenantId = "{azure-tenantId}";
            string clientId = "{clientId}";
            string clientSecret = "{client secret of registered app}";
            string subscriptionId = "{azure-subscriptionId}";
            string resourceGroupName = "{azure-resourceGroupName}";
            string vmName = "{azure-vm-name}";
            var app = ConfidentialClientApplicationBuilder.Create(clientId).WithClientSecret(clientSecret).WithTenantId(tenantId).Build();
            var authResult = await app.AcquireTokenForClient(new string[] {
            "https://management.azure.com/.default"
            }).ExecuteAsync();
            // Use the access token to authenticate the API call
            var httpClient = new HttpClient();
            httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", authResult.AccessToken);

            // API Call to Get VM Details
            var response = await httpClient.GetAsync("https://management.azure.com/subscriptions/" + subscriptionId + "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Compute/virtualMachines/" + vmName + "?api-version=2022-08-01");
            if (response.IsSuccessStatusCode) {
            // Retrieve the response content as a JSON string
            var jsonString = await response.Content.ReadAsStringAsync();
    
            Console.WriteLine(JObject.Parse(jsonString));
            } else {
                throw new Exception("Failed to retrieve VM metadata:" );
            }
        }
    }
}