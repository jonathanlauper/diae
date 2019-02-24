var testing12345;
var currentImage;
    var currentFile;
    var identifier;
    var collection;

    async function recognize() {
/*        document.getElementById("orig_image").style.visibility = 'visible';
*/      toDataURL(document.getElementById("orig_image").currentSrc, async function(dataUrl){
            console.log(dataUrl);
            currentImage = dataUrl;
            currentFile = {
                name: "test.png"
            };
            await uploadImage();
            await binarize();
            await segment();
            await recText();
        });
/*        document.getElementById("spinner").style.visibility = 'hidden';
*/    }

    function recText() {
        return new Promise(resolve => {
            var data = JSON.stringify({
                "parameters": {},
                "data": [
                    {
                        "dataFolder": collection,
                        "recognitionModel": "ocr_models/english.gz"
                    }
                ]
            });
            fetch("http://divaservices.unifr.ch/api/v2/ocr/ocropusrecognize/1", {
                method: "POST",
                body: data,
                headers: new Headers({ 'content-type': 'application/json' })
            }).then(function (res) {
                return res.json();
            }).then(async function (data) {
                var result = await getResult(data.results[0].resultLink);
                var text = "";
                for (var index = 0; index < result.output.length; index++) {
                    var element = result.output[index];
                    if (Object.keys(element)[0] === "file") {
                        if (element.file["mime-type"] === "text/plain" && !(element.file.type === "log")) {
                            text += await getText(element);
                        }
                    }
                }
                console.log("text:" + text);
                document.getElementById("result").innerHTML = text;
                resolve();
            });
        });
    }

    function getText(element) {
        return new Promise(resolve => {
            fetch(element.file.url, {
                method: "GET"
            }).then(async function (res) {
                resolve(await res.text() + "<br />");
            });
        });
    }

    function segment() {
        return new Promise(resolve => {
            var data = JSON.stringify({
                "parameters": {},
                "data": [
                    {
                        "inputImage": identifier
                    }
                ]
            });

            fetch("http://divaservices.unifr.ch/api/v2/segmentation/ocropuspagesegmentation/1", {
                method: "POST",
                body: data,
                headers: new Headers({ 'content-type': 'application/json' })
            }).then(function (res) {
                return res.json();
            }).then(async function (data) {
                var result = await getResult(data.results[0].resultLink);
/*                document.getElementById("segmentation").src = result.output[0].file.url
*/
                first = true;
                for (var index = 0; index < result.output.length; index++) {
                    var element = result.output[index];
                    if (Object.keys(element)[0] === "file") {
                        if (element.file["mime-type"].includes("image/png") && !(element.file.name.includes("segmentationImage"))) {
                            if (first) {
                                first = false;
                                await uploadImageUrl(element)
                            } else {
                                await addImageUrl(element);
                            }
                        }
                    }
                }
                resolve();
            });
        });
    }

    function binarize() {
        return new Promise(resolve => {
            var data = JSON.stringify({
                "parameters": {
                    "enableSkew":false,
                    "maxskew":2.0,
                    "skewsteps":8.0
                },
                "data": [
                    {
                        "inputImage": identifier
                    }
                ]
            });
            
            fetch("http://divaservices.unifr.ch/api/v2/binarization/ocropusbinarization/1", {
                method: "POST",
                body: data,
                headers: new Headers({ 'content-type': 'application/json' })
            }).then(function (res) {
                return res.json();
            }).then(async function (data) {
                var result = await getResult(data.results[0].resultLink);
                document.getElementById("binarisation").src = result.output[0].file.url;
                var data = JSON.stringify({
                    "files": [
                        {
                            "type": "url",
                            "value": result.output[0].file.url,
                            "name": result.output[0].file.name.split(".")[0],
                            "extension": "bin.png"
                        }
                    ]
                });
                identifier = collection + "/" + result.output[0].file.name.split(".")[0] + ".bin.png"
                fetch("http://divaservices.unifr.ch/api/v2/collections/" + collection, {
                    method: "PUT",
                    body: data,
                    headers: new Headers({ 'content-type': 'application/json' })
                }).then(function (res) {
                    return res.json();
                }).then(async function (data) {
                    resolve();
                });
            });
        });
    }

    /**
     * 
     * Fetch the result from a given url
     * Polls for the result every 1000ms (1s)
     *  
     * */
    function getResult(url) {
        return new Promise(resolve => {
            fetch(url, {
                method: "GET"
            }).then(function (res) {
                return res.json();
            }).then(function (data) {
                if (data.status === "done") {
                    resolve(data);
                } else {
                    setTimeout(function () {
                        resolve(getResult(url));
                    }, 1000);
                }
            });
        });
    }

    /**
     * Get the result from an upload operation
     * Polls every 1000ms (1s) to check if the collection is available
     * 
     * */
    function getUploadResult(collectionName) {
        return new Promise(resolve => {
            fetch('http://divaservices.unifr.ch/api/v2/collections/' + collectionName, {
                method: "GET"
            }).then(function (res) {
                return res.json();
            }).then(function (data) {
                if (data.statusCode === 200) {
                    resolve(data.files[0].file.identifier);
                } else {
                    setTimeout(function () {
                        resolve(getUploadResult(collectionName));
                    }, 1000);
                }
            })
        })
    }

    function toDataURL(url, callback) {
      var xhr = new XMLHttpRequest();
      xhr.onload = function() {
        var reader = new FileReader();
        reader.onloadend = function() {
          callback(reader.result);
        }
        reader.readAsDataURL(xhr.response);
      };
      xhr.open('GET', url);
      xhr.responseType = 'blob';
      xhr.send();
    }

    function uploadImageUrl(element) {
        var tmpData = JSON.stringify({
            "files": [
                {
                    "type": "url",
                    "value": element.file.url,
                    "name": element.file.name.split(".")[0],
                    "extension": "bin.png"
                }
            ]
        });
        return new Promise(resolve => {
            fetch("http://divaservices.unifr.ch/api/v2/collections", {
                method: "POST",
                body: tmpData,
                headers: new Headers({ 'content-type': 'application/json' })
            }).then(function (res) {
                return res.json();
            }).then(async function (data) {
                collection = data.collection;
                resolve();
            });
        });
    }

    function addImageUrl(element) {
        var tmpData = JSON.stringify({
            "files": [
                {
                    "type": "url",
                    "value": element.file.url,
                    "name": element.file.name.split(".")[0],
                    "extension": "bin.png"
                }
            ]
        });
        return new Promise(resolve => {
            fetch("http://divaservices.unifr.ch/api/v2/collections/" + collection, {
                method: "PUT",
                body: tmpData,
                headers: new Headers({ 'content-type': 'application/json' })
            }).then(function (res) {
                return res.json();
            }).then(async function (data) {
                resolve();
            });
        });
    }

    /**
     * Uploads the current image to DIVAServices
     * */
    function uploadImage() {
        /**Add collection with own name
        {
          "name":"YourCollectionName",
          "files":[...]
        }
        */
        return new Promise(resolve => {
            var data = JSON.stringify({
              /*  "files": [
                    {
                        "type": "base64",
                        "value": currentImage,
                        "name": currentFile.name.split('.')[0],
                        "extension": currentFile.name.split('.')[1]
                    }*/
            "name":"YourCollectionName",
            "files":[                    
                   {
                        "type": "base64",
                        "value": currentImage,
                        "name": currentFile.name.split('.')[0],
                        "extension": currentFile.name.split('.')[1]
                    }]
            });
            fetch("http://divaservices.unifr.ch/api/v2/collections", {
                method: "POST",
                body: data,
                headers: new Headers({ 'content-type': 'application/json' })
            }).then(function (res) {
                if(!res.ok){
                    throw Error(response);
                }else{
                    return res.json();
                }
            }).then(async function (data) {
                collection = data.collection;
                identifier = await getUploadResult(data.collection);
                console.log("created collection: " + identifier);
                resolve();
            }).catch(function(error){
                collection = "YourCollectionName";
                identifier = "YourCollectionName/test.png";
                resolve();
            });
        });
    }
