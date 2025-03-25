<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>default</title>
    <style>
        body, html {
            margin: 0;
            padding: 0;
            height: 100%;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            background-color: #d4cebc;
            text-align: center;
            overflow: hidden;
        }

        h1 {
            margin-top: 50px;
            font-size: 24px;
            color: #333;
            white-space: nowrap;
            text-overflow: ellipsis;
            transform: rotate(-5deg);
        }

        img {
            width: 100%;
            max-height: 80%;
            object-fit: contain;
        }
    </style>
</head>
<body>
    <h1><?php print "default php page" ?></h1>
    <img src="default.png">
</body>
</html>
