using Microsoft.AspNetCore.Mvc;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

namespace demo3.Controllers;

[ApiController]
[Route("[controller]")]
public class WeatherForecastController : ControllerBase
{
    private static readonly string[] Summaries = new[]
    {
        "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
    };

    private readonly ILogger<WeatherForecastController> _logger;

    public WeatherForecastController(ILogger<WeatherForecastController> logger)
    {
        _logger = logger;
    }

    [HttpGet(Name = "GetWeatherForecast")]
    public IEnumerable<WeatherForecast> Get()
    {
        return Enumerable.Range(1, 5).Select(index => new WeatherForecast
        {
            Date = DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            TemperatureC = Random.Shared.Next(-20, 55),
            Summary = Summaries[Random.Shared.Next(Summaries.Length)]
        })
        .ToArray();
    }

    [HttpGet(Name = "GetSecret")]
    public string GetSecret()
    {
        string keyVaultUrl = Environment.GetEnvironmentVariable("KEYVAULT_URL");
        string secretName = Environment.GetEnvironmentVariable("SECRET_NAME");

        var kvUri = "https://" + keyVaultUrl + ".vault.azure.net";

        var client = new SecretClient(
            new Uri(kvUri),
            new DefaultAzureCredential());

        KeyVaultSecret secret = client.GetSecretAsync(secretName).Result;


        return secret.Value;
    }
}
