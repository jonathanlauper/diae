
    var currentImage;
    var currentFile;
    var identifier;

    /**
     * Perform OCRopus Binarization with skew correction
     * */
    async function ocropusBinarization() {
        document.getElementById("spinner").style.visibility = 'visible';
        var data = JSON.stringify({
            "parameters": {
                "enableSkew": "true",
                "maxskew": Number(document.getElementById("maxskew_slider").value),
                "skewsteps": Number(document.getElementById("skewsteps_slider").value)
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
            document.getElementById("ocropus").src = result.output[0].file.url
            document.getElementById("spinner").style.visibility = 'hidden';

        })
    }

    /**
     * Perform Otsu Binarization
     * */
    async function otsuBinarization() {
    var saveData = (function () {
    var a = document.createElement("a");
    document.body.appendChild(a);
    a.style = "display: none";
    return function (data, fileName) {
        var json = JSON.stringify(data),
            blob = new Blob([json], {type: "octet/stream"}),
            url = window.URL.createObjectURL(blob);
        a.href = url;
        a.download = fileName;
        a.click();
        window.URL.revokeObjectURL(url);
    };
}());

        document.getElementById("spinner").style.visibility = 'visible';
        var data = JSON.stringify({
            "parameters": {},
            "data": [
                {
                    "inputImage": identifier
                }
            ]
        });

        fetch("http://divaservices.unifr.ch/api/v2/binarization/otsubinarization/1", {
            method: "POST",
            body: data,
            headers: new Headers({ 'content-type': 'application/json' })
        }).then(function (res) {
            return res.json();
        }).then(async function (data) {
            var result = await getResult(data.results[0].resultLink);
            document.getElementById("otsu").src = result.output[0].file.url
            document.getElementById("spinner").style.visibility = 'hidden';
            var data = result.output[0].file.url,
    fileName = "my-download.json";

saveData(result, fileName);
        })
              


        
    }


    /**
     * Perform Sauvola Binarization
     * */
    async function sauvolaBinarization() {
        document.getElementById("spinner").style.visibility = 'visible';
        var data = JSON.stringify({
            "parameters": {
                "radius": 15,
                "thres_tune": 0.3
            },
            "data": [
                {
                    "inputImage": identifier
                }
            ]
        });

        fetch("http://divaservices.unifr.ch/api/v2/binarization/sauvolabinarization/1", {
            method: "POST",
            body: data,
            headers: new Headers({ 'content-type': 'application/json' })
        }).then(function (res) {
            return res.json();
        }).then(async function (data) {
            var result = await getResult(data.results[0].resultLink);
            document.getElementById("sauvola").src = result.output[0].file.url
            document.getElementById("spinner").style.visibility = 'hidden';
        })
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
            })
        })
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

    /**
     * Encodes the image as base64 string to upload it to DIVAServices
     * the results are stored in the global variables 'currentFile' and 'currentImage'
     * 
     * */
    function encodeImageFileAsURL(element) {
        var file = element.files[0];
        var reader = new FileReader();
        reader.onloadend = function () {
            currentImage = reader.result;
            currentFile = file;
            uploadImage();
        }
        reader.onload = function (e) {
            document.getElementById('orig_image').src = e.target.result;
            document.getElementById('upload_info').style.display = 'none';
        }

        reader.readAsDataURL(file);

    }

    /**
     * Uploads the current image to DIVAServices
     * */
    function uploadImage() {
        var data = JSON.stringify({
            "files": [
                {
                    "type": "base64",
                    "value": currentImage,
                    "name": currentFile.name.split('.')[0],
                    "extension": currentFile.name.split('.')[1]
                }
            ]
        });
        fetch("http://divaservices.unifr.ch/api/v2/collections", {
            method: "POST",
            body: data,
            headers: new Headers({ 'content-type': 'application/json' })
        }).then(function (res) {
            return res.json();
        }).then(async function (data) {
            identifier = await getUploadResult(data.collection);
            document.getElementById('otsuBtn').disabled = false;
            document.getElementById('sauvolaBtn').disabled = false;
            document.getElementById('ocropusBtn').disabled = false;
        })
    }
    function updateMaxskew() {
        document.getElementById("maxSkewCurrentValue").innerHTML = "maxskew: " + document.getElementById("maxskew_slider").value;
    }
    function updateSkewSteps() {
        document.getElementById("skewStepsCurrentValue").innerHTML = "skewsteps: " + document.getElementById("skewsteps_slider").value;
    }
    function updateThresh() {
        document.getElementById("threshCurrentValue").innerHTML = "Threshold: " + document.getElementById("thresh_slider").value;
    }
    function updateGauss1() {
        document.getElementById("gauss1CurrentValue").innerHTML = "Gauss1: " + document.getElementById("gauss1_slider").value;
    }
    function updateGauss2() {
        document.getElementById("gauss2CurrentValue").innerHTML = "Gauss2: " + document.getElementById("gauss2_slider").value;
    }
