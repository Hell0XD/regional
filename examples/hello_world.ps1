using module "./../Regional.psm1"

$app = [App]::new();

$app.Get("/", { 
        Param($headers, $setStatus, $setContentType)

        &$setStatus 200;
        &$setContentType "text/html";

        return "Hello world";
    });

$app.Listen();