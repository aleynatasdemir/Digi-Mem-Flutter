using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace DigiMem.Filters;

public class FileUploadOperation : IOperationFilter
{
    public void Apply(OpenApiOperation operation, OperationFilterContext context)
    {
        var fileUploadMime = "multipart/form-data";
        
        if (operation.RequestBody == null)
            return;

        if (!operation.RequestBody.Content.Any(x => x.Key == fileUploadMime))
            return;

        var fileParams = context.MethodInfo
            .GetParameters()
            .Where(p => p.ParameterType == typeof(IFormFile))
            .ToList();

        operation.RequestBody.Content[fileUploadMime].Schema.Properties =
            fileParams.ToDictionary(
                p => p.Name,
                p => new OpenApiSchema()
                {
                    Type = "string",
                    Format = "binary"
                }
            );
    }
}
