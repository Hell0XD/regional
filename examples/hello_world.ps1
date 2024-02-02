using module "./../Regional.psm1"

$app = [App]::new();

$app.Get("/", { 
        Param($req, $res)

        $res.Status(200)
        $res.Json(@{
            message = "Hello world"
        })
    });

$app.Listen();