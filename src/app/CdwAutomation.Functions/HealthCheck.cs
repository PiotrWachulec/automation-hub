using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace CdwAutomation.Functions
{
    public class HealthCheck
    {
        private readonly ILogger<HealthCheck> _logger;

        public HealthCheck(ILogger<HealthCheck> logger)
        {
            _logger = logger;
        }

        [Function("HealthCheck")]
        public IActionResult Run([HttpTrigger(AuthorizationLevel.Anonymous, "get")] HttpRequest req)
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");
            return new OkObjectResult("All good, keep going!");
        }
    }
}
