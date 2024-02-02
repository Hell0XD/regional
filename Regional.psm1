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

    hidden [Void] AddRoute([String] $path, [String] $method, [scriptblock] $handler) {
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
    
            $res = [Response]::new($context.Response);
            $req = [Request]::new($context.Request);

            $handler_map = $this.handlers | Where-Object { $_.Path -eq $req.path } | Where-Object { $_.Method -eq "*" -or $_.Method -eq $req.method };
    
            if ($null -eq $handler_map) {
                $res.Status(404);
                $res.Send("not found");
            } else {
                $handler = $handler_map["Handler"];
                &$handler -req $req -res $res
            }
    
            $context.Response.Close();
        }
    
        $httpListener.Close();
    }
}


class Request {
    hidden [System.Net.HttpListenerRequest] $request
    [String] $method;
    [String] $path;
    [String] $hostname;

    $body;

    Request([System.Net.HttpListenerRequest] $request) {
        $this.request = $request;
        $this.method = $request.HttpMethod;
        $this.path = $request.Url.AbsolutePath;
        $this.hostname = $request.Url.Host;

        $requestBodyReader = New-Object System.IO.StreamReader $request.InputStream;
        $this.body = $requestBodyReader.ReadToEnd();
    }
}


class Response {
    hidden [System.Net.HttpListenerResponse] $response

    Response([System.Net.HttpListenerResponse] $response) {
        $this.response = $response;
    }

    [void] Status([UInt16] $status) {
        $this.response.StatusCode = $status;
    }

    [void] Type([String] $type) {
        $this.response.ContentType = $type;
    }

    [void] Send([String] $msg) {
        $responseBytes = [System.Text.Encoding]::UTF8.GetBytes($msg);
        $this.response.OutputStream.Write($responseBytes, 0, $responseBytes.Length);
    }

    [void] Json([Object] $json) {
        $msg = $json | ConvertTo-Json;

        $this.Type("application/json");
        $this.Send($msg);
    }
}