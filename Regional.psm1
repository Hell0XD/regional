class App {
    $handlers = @();

    [Void] Get([String] $path, [scriptblock] $handler) {
        $this.AddRoute($path, "GET", $handler);
    }

    [Void] Post([String] $path, [scriptblock] $handler) {
        $this.AddRoute($path, "POST", $handler);
    }

    [Void] Put([String] $path, [scriptblock] $handler) {
        $this.AddRoute($path, "PUT", $handler);
    }
    
    [Void] Delete([String] $path, [scriptblock] $handler) {
        $this.AddRoute($path, "DELETE", $handler);
    }

    [Void] All([String] $path, [scriptblock] $handler) {
        $this.AddRoute($path, "*", $handler);
    }

    [Void] AddRoute([String] $path, [String] $method, [scriptblock] $handler) {
        $this.handlers += @{
            Handler = $handler
            Method  = $method
            Path    = $path
        };
    }

    [Void] Listen() {
        $this.Listen(9999);
    }
    [Void] Listen([Int16] $port) {
        $this.Listen($port, "localhost");
    }
    [Void] Listen([Int16] $port, [String] $_host) {
        $httpListener = New-Object System.Net.HttpListener;
        $httpListener.Prefixes.Add("http://${_host}:${port}/");

        $httpListener.Start();
        Write-Host "Listening on port ${port}!";
    
        while ($true) {
            $context = $httpListener.GetContext();
    
            $method = $context.Request.HttpMethod;
            $url = $context.Request.Url;
            $requestBodyReader = New-Object System.IO.StreamReader $context.Request.InputStream;
            $body = $requestBodyReader.ReadToEnd();
    
            $handler_map = ($this.handlers | Where-Object { $_.Path -eq $url.AbsolutePath } | Where-Object { $_.Method -eq "*" -or $_.Method -eq $method } );
    
            if ($null -eq $handler_map) {
                $context.Response.StatusCode = 404;
                $responseBytes = [System.Text.Encoding]::UTF8.GetBytes("not found");
                $context.Response.OutputStream.Write($responseBytes, 0, $responseBytes.Length);
            }
            else {
                $handler = $handler_map["Handler"];
                $response = &$handler -headers $context.Request.Headers -body $body -setStatus {
                    Param([byte] $status)
                    $context.Response.StatusCode = $status;
                } -setContentType {
                    Param([String] $content_type)
                    $context.Response.ContentType = $content_type;
                };
    
                $responseBytes = [System.Text.Encoding]::UTF8.GetBytes($response);
                $context.Response.OutputStream.Write($responseBytes, 0, $responseBytes.Length);
            }
    
            $context.Response.Close();
        }
    
        $httpListener.Close();
    }
}