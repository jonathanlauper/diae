//ctx.strokeStyle = '#fff';


var imageCounter = 1;
var folderCounter = 1;

var canvasses;

window.onload = function(){
    canvasses = [new CanvasWrapper(document.getElementById('mainView'))];
console.log(document.getElementById('orig_image').src);    canvasses[0].addImage(document.getElementById('orig_image').src, true);

    canvasses[0].addImage('/exist/projects/diae/recognize/image2.png', true);
	//canvasses[0].addImage('/images/folder1/image1.jpg', true);
}

function Polygon(){
	this.points = [];
	this.addPoint = function(point){
		this.points.push(point);
	}
	this.getCopy = function(){
		var p2 = new Polygon();
		this.points.forEach(function(point){p2.addPoint(point.getCopy())});
		return p2;
	}
	this.pointAt = function(pos, wrapper){
		var reverseScale = 1/wrapper.scale;
		var corrected = pos.multiply(1/wrapper.scale); console.log("pos: "+pos.x+"/"+pos.y+" corr: "+corrected.x+"/"+corrected.y);
		for(index = 0; index < this.points.length; ++index){ 
			if(this.points[index].distance(corrected) <= 6){console.log("p: "+this.points[index].x+"/"+this.points[index].y);
				return this.points[index];
			}
		}console.log("\n");
		return -1;
	}
	this.split = function(point){
		var addAt;
		for(index = 0; index < this.points.length; ++index){
			if(this.points[index].equal(point)){
				addAt = index;
			}
		}
		var newPoints = [];
		for(index = 0; index < this.points.length; ++index){
			newPoints.push(this.points[index]);
			if(index == addAt)
				newPoints.push(point.getCopy());
		}
		this.points = newPoints;
	}
	this.remove = function(point){
		for(index = 0; index < this.points.length; ++index){
			if(this.points[index].equal(point)){
				this.points.splice(index,1);
			}
		}
	}
    this.draw = function(ctx, translate, scale, mode){
		if(this.points.length == 0)
			return;
		start = this.points[0].multiply(scale).translate(translate);
		prev = start; ctx.fillStyle = "rgba(255, 0, 0, 1)";
		if(mode == 1)//if mode 1 draw point a bit thicker
			ctx.fillRect(start.x-3, start.y-3, 6, 6); ctx.fillStyle = "rgba(0, 0, 0, 1)";
		for(index = 1; index < this.points.length; ++index){
			current = this.points[index].multiply(scale).translate(translate);
			if(mode == 1)//if mode 1 draw point a bit thicker
				ctx.fillRect(current.x-3, current.y-3, 6, 6);
			ctx.beginPath();
			ctx.moveTo(prev.x, prev.y);
			ctx.lineTo(current.x, current.y);
			if(index == this.points.length-1){//connect last point to start
				ctx.moveTo(current.x, current.y);
				ctx.lineTo(start.x, start.y);
			}
			ctx.stroke();
			prev = current;
		}
    }
	this.getBoundingRectangle = function(){
		var minX = Number.MAX_VALUE;
		var maxX = Number.MIN_VALUE;
		var minY = Number.MAX_VALUE;
		var maxY = Number.MIN_VALUE;

		for(i = 0; i < this.points.length; i++) {
			var x = this.points[i].x;
			var y = this.points[i].y;
			minX = Math.min(minX, x);
			maxX = Math.max(maxX, x);
			minY = Math.min(minY, y);
			maxY = Math.max(maxY, y);     
		}
		return new Rectangle(minX, minY, maxX-minX, maxY-minY);
	}
}
function Rectangle(x, y, width, height){
	this.x = x;
	this.y = y;
	this.width = width;
	this.height = height;
}
function Point(x, y){
	this.x = x;
	this.y = y;
	this.getCopy = function(){
		return new Point(this.x, this.y);
	}
	this.translate = function(by){
		return new Point(this.x+by.x, this.y+by.y);
	}
	this.multiply = function(by){
		return new Point(this.x*by, this.y*by);
	}
	this.distance = function(p2){
		return Math.sqrt(((this.x-p2.x)*(this.x-p2.x))+(this.y-p2.y)*(this.y-p2.y))
	}
	this.equal = function(p2){
		return (this.x == p2.x && this.y == p2.y);
	}
}

var fixedBoxes = [];
var boxes = [];

function CanvasWrapper(element) {
    this.canvas = element;
    this.images = [];
	this.loaded = false;
	this.scale = 1;
	this.posX = [0];
	this.posY = [0];
	this.deltaX = [0];
	this.deltaY = [0];
	this.mode = 0;
	this.movingIndex = -1;
	this.addImage = function(source, isUrl){
		if(isUrl){
			var img = new Image();
			img.src = source;
			console.log("1"+ img.width);
			this.images[this.images.length] = img;
			//console.log("2"+ this.images[0].src);
			img.onload = start;
		}else{
			this.images[this.images.length] = source;
		}
		if(this.images.length >1){ //TODO correct this abomination of a position system
			this.deltaX[this.images.length-1] = this.deltaX[this.images.length-2];
			this.deltaY[this.images.length-1] = this.deltaY[this.images.length-2]-this.images[this.images.length-2].height-20;
		}
	}	
	this.pointOnWhichImage = function(point){
		for(i=0; i<this.images.length; i++){
			if( this.posX[i]<=point.x && (this.posX[i]+(this.images[i].width*this.scale))>=point.x 
		     && this.posY[i]<=point.y && (this.posY[i]+(this.images[i].height*this.scale))>=point.y){
				return i;
			}
		}
		return -1;
	}
	this.canvas.onwheel = onScrolling;
	this.canvas.onmousedown = onMouseDown;
	this.canvas.onmousemove = onMouseMove;
	this.canvas.onmouseup = onMouseUp;
	this.canvas.addEventListener('contextmenu', function(e) {
            e.preventDefault();
        }, false);
}

function start(){
	display(canvasses[0]);
}


function display(canvasWrapper){
	cleanUp(canvasWrapper);
	var width = canvasWrapper.canvas.width;
	var height = canvasWrapper.canvas.height;
	
	var imgWidth = canvasWrapper.images[0].width;
	var imgHeight = canvasWrapper.images[0].height;
	var scaleX = 1, scaleY = 1;
	if(imgWidth > width)
		scaleX = width/imgWidth;
	if(imgHeight > height)
		scaleY = height/imgHeight;
	if(scaleY < scaleX)
		canvasWrapper.scale = Math.floor(scaleY*10)/10;
	else
		canvasWrapper.scale = Math.floor(scaleX*10)/10;
		
	document.getElementById('log').innerHTML = 'Scale '+canvasWrapper.scale;
	updateCanvas(canvasWrapper);
}

function updateCanvas(canvasWrapper){
//console.log("ads "+canvasWrapper.images[0].src);

	if(canvasWrapper.canvas.id != "view4"){
		var width = canvasWrapper.canvas.width, height = canvasWrapper.canvas.height;
		var ctx = canvasWrapper.canvas.getContext('2d');     
		ctx.fillStyle = "rgba(0, 0, 0, 1)";

		var imgWidth = canvasWrapper.images[0].width;
		var imgHeight = canvasWrapper.images[0].height;
		
		var newImgWidth = imgWidth * canvasWrapper.scale;
		var newImgHeight = imgHeight * canvasWrapper.scale;
		canvasWrapper.posX[0] = (width - newImgWidth)/2 - canvasWrapper.deltaX[0];
		canvasWrapper.posY[0] = (height - newImgHeight)/2 - canvasWrapper.deltaY[0];

		ctx.clearRect(0, 0, width, height); 
		ctx.beginPath();
        ctx.rect(0, 0, width, height);
		ctx.fill();
		ctx.drawImage(canvasWrapper.images[0], canvasWrapper.posX[0], canvasWrapper.posY[0], newImgWidth, newImgHeight);
		


		if(canvasWrapper.canvas.id == "view2"){
			//console.log("l "+fixedBoxes.length);
			fixedBoxes.forEach(function(polygon){polygon.draw(ctx,new Point(canvasWrapper.posX[0],canvasWrapper.posY[0]),canvasWrapper.scale,canvasWrapper.mode);})
		}else if(canvasWrapper.canvas.id == "view3"){	
			boxes.forEach(function(polygon){polygon.draw(ctx,new Point(canvasWrapper.posX[0],canvasWrapper.posY[0]),canvasWrapper.scale,canvasWrapper.mode);})
			if(drawnewbox){	
				ctx.rect(newPolygon.x,newPolygon.y,mouse.x-newPolygon.x,mouse.y-newPolygon.y);
				ctx.stroke();
			}
		}
	}else if(canvasWrapper.canvas.id == "view4"){	
		var width = canvasWrapper.canvas.width, height = canvasWrapper.canvas.height;
		var ctx = canvasWrapper.canvas.getContext('2d');     
		ctx.fillStyle = "rgba(0, 0, 0, 1)";
		var dis = 1;
		
		//console.log(canvasWrapper.images.length);
		var imgWidth = [];
		var imgHeight = [];
		ctx.clearRect(0, 0, width, height); 		
		ctx.beginPath();
        ctx.rect(0, 0, width, height);
        ctx.fill();
		for(i = 0 ; i<canvasWrapper.images.length; i++){   
			imgWidth[i] = canvasWrapper.images[i].width;
			imgHeight[i] = canvasWrapper.images[i].height;
			var newImgWidth = imgWidth[i] * canvasWrapper.scale;
			var newImgHeight = imgHeight[i] * canvasWrapper.scale;
			canvasWrapper.posX[i] = (width - newImgWidth)/2 - canvasWrapper.deltaX[i];
			canvasWrapper.posY[i] = -canvasWrapper.deltaY[i];
			
			
			//console.log("image "+i+"pos: "+canvasWrapper.posX[i]+"/"+canvasWrapper.posY[i]);
			ctx.drawImage(canvasWrapper.images[i], canvasWrapper.posX[i], canvasWrapper.posY[i], newImgWidth, newImgHeight);
		}
		

			
			/*		for(i = 0; i<canvasWrapper.canvas.images.length; i++){}
			*/
	}
	//Toolbar
	ctx.fillStyle = "rgba(192, 192, 192, 0.5)";
	ctx.fillRect(0, 0, width, 20);
	ctx.fillStyle = "rgba(0, 0, 0, 1)";
	
	/*
	line1.draw(ctx);
	line2.draw(ctx);
	line3.draw(ctx);
	line4.draw(ctx);
	line5.draw(ctx);
	line6.draw(ctx);
	line7.draw(ctx);
	*/
	ctx.fillStyle = "rgba(0, 0, 0, 1)";
	ctx.font = "bold 10pt Arial";
	ctx.fillText( Math.trunc(canvasWrapper.scale*100)+"%",width-50,15);
	ctx.fillText( "Collection "+folderCounter+"  Image "+imageCounter,width/2-30,15);
	ctx.fillText( "pI" ,2,15);
	ctx.fillText( "nI" ,2+arrowSpacing,15);
	ctx.fillText( "pC" ,2+2*arrowSpacing,15);
	ctx.fillText( "nC" ,2+3*arrowSpacing,15);
}

function executeAlgorithm(algorithm){
	if(algorithm == "textlines"){
		canvasses[1] = new CanvasWrapper(document.getElementById('view2'));
		var img = new Image();
		img.src = canvasses[0].images[0].src;//or some subpart of image if selected
		canvasses[1].addImage(img, false);
		img.onload = display(canvasses[1]);
		
		
		//Draw boxes on (ie. run segmentation algorithm once acutally here)
		var p1 = new Polygon();
		var p2 = new Polygon();
		p1.addPoint(new Point(100,100));
		p1.addPoint(new Point(400,100));
		p1.addPoint(new Point(400,200));
		p1.addPoint(new Point(100,200));
		
		p2.addPoint(new Point(100,300));
		p2.addPoint(new Point(400,300));
		p2.addPoint(new Point(400,400));
		p2.addPoint(new Point(100,400));

		fixedBoxes.push(p1);
		fixedBoxes.push(p2);
		
		boxes.push(p1.getCopy());
		boxes.push(p2.getCopy());
		
		canvasses[2] = new CanvasWrapper(document.getElementById('view3'));
		var img = new Image();
		img.src = canvasses[0].images[0].src;//or some subpart of image if selected
		canvasses[2].addImage(img, false);
		img.onload = display(canvasses[2]);
		
		canvasses.forEach(function(canvas){updateCanvas(canvas);});
		
	}else if(algorithm == "extractImages"){
		canvasses[3] = new CanvasWrapper(document.getElementById('view4'));
		var workOn = new Image();
		
		workOn.onload = function(){
			var imageUrls = [];
			boxes.forEach(function(polygon){
				var rect = polygon.getBoundingRectangle();
				imageUrls.push(getImagePart(workOn, rect.x, rect.y, rect.width, rect.height, polygon))
			});
		
			imageUrls.forEach(function(dataUrl){
				var img = new Image();
				img.onload = function(){
					canvasses[3].addImage(img, false);
				}
				img.src = dataUrl; 
			});
			
			canvasses.forEach(function(canvas){updateCanvas(canvas);});
		}
		workOn.src = canvasses[2].images[0].src;
	}
}
function getImagePart(img, x, y, width, height, polygon){
	var result = document.createElement('canvas');
	var ctx = result.getContext('2d');
	result.width = width; 
	result.height = height;

	var temp = document.createElement('canvas');
	var tempCtx = temp.getContext('2d');
	temp.width = img.width;
	temp.height = img.height;
	tempCtx.drawImage(img, 0, 0);

	ctx.drawImage(temp, x, y, width, height, 0, 0, width,height);
	//white out pixels outside of polygon
	for(var w = 0; w<width; w++){
		for(var h = 0; h<height; h++){
			if(!pnpoly(polygon, w+x, h+y)){//true if point outside polygon
				ctx.fillStyle = "rgba(255, 255, 255, 1)";	
				ctx.fillRect(w, h, 1, 1);
			}
		}
	}
	
	
	
	//console.log("dta "+result.toDataURL("image/png")+"\n");
	return result.toDataURL("image/png");
}

function pnpoly(polygon, testx, testy){//x y inside polygon //Copyright (c) 1970-2003, Wm. Randolph Franklin - https://wrf.ecse.rpi.edu//Research/Short_Notes/pnpoly.html
	var nvert = polygon.points.length;
	var i, j, c = 0;
	for(var i = 0, j = nvert-1; i < nvert; j = i++) {
		if ( ((polygon.points[i].y>testy) != (polygon.points[j].y>testy)) &&
		(testx < (polygon.points[j].x-polygon.points[i].x) * (testy-polygon.points[i].y) / (polygon.points[j].y-polygon.points[i].y) + polygon.points[i].x) )
			c = !c;
	}
	return c;//odd=1 even=0 odd=inside even=outside
}
/*
    if ( ((verty[i]>testy) != (verty[j]>testy)) &&
     (testx < (vertx[j]-vertx[i]) * (testy-verty[i]) / (verty[j]-verty[i]) + vertx[i]) )
       c = !c;
*/

function getImagePart2(img, x, y, width, height){
	img.setAttribute('crossOrigin', '');
	var result = document.createElement('canvas');
	var ctx = result.getContext('2d');
	result.width = width; 
	result.height = height;

	var temp = document.createElement('canvas');
	var tempCtx = temp.getContext('2d');
	temp.width = img.width;
	temp.height = img.height;
	console.log("d"+temp.width+"\n");
	tempCtx.drawImage(img, 0, 0);
	var imageData = tempCtx.getImageData(x,y,width,height);
	
	

	ctx.putImageData(imageData, 0, 0);
	console.log("data "+result.toDataURL("image/png")+"\n");
	return result.toDataURL("image/png");
}

function cleanUp(wrapper){
	wrapper.scale = 1;
	wrapper.deltaX = [0];
	wrapper.deltaY = [0];
	down = 0;
	timestamp = 0;
	scrolltimer = 0;
}

function nextImage(){
	if(imageCounter < 4)
		imageCounter++;
	else
		imageCounter = 1;
	image = new Image();
	img.src = 'images/folder'+folderCounter+'/image'+imageCounter+'.jpg';
	img.onload = start;
}
function previousImage(){
	if(imageCounter > 1)
		imageCounter--;
	else
		imageCounter = 4;
	image = new Image();
	img.src = 'images/folder'+folderCounter+'/image'+imageCounter+'.jpg';
	img.onload = start;
}
function nextCollection(){
	if(folderCounter < 3)
		folderCounter++;
	else
		folderCounter = 1;
	image = new Image();
	img.src = 'images/folder'+folderCounter+'/image'+imageCounter+'.jpg';
	img.onload = start;
}
function previousCollection(){
	if(folderCounter > 1)
		folderCounter--;
	else
		folderCounter = 3;
	image = new Image();
	img.src = 'images/folder'+folderCounter+'/image'+imageCounter+'.jpg';
	img.onload = start;
}

function scaleUp(wrapper){	
	console.log('scaleUp');
	wrapper.scale += 0.1;
	updateCanvas(wrapper);
}
function scaleDown(wrapper){
	console.log('scaleDown');
	wrapper.scale -= 0.1;
	updateCanvas(wrapper);
}

var mode = 0;
window.addEventListener('keypress', function(event){

    var keynum;

    if(window.event) { // IE                    
      keynum = event.keyCode;
    }else if(event.key){ // Netscape/Firefox/Opera                   
      keynum = event.keyCode || event.charCode;
    }
	if(String.fromCharCode(keynum) == "r")
		executeAlgorithm("textlines");
	if(String.fromCharCode(keynum) == "m"){
		if(canvasses[2].mode == 0)
			canvasses[2].mode = 1;
		else if(canvasses[2].mode == 1)
			canvasses[2].mode = 0;
	}
	if(String.fromCharCode(keynum) == "p")
		executeAlgorithm("extractImages");
		
	if(String.fromCharCode(keynum) == "l"){
		if(canvasses[2].mode == 0)
			canvasses[2].mode = 1;
		else if(canvasses[2].mode == 1)
			canvasses[2].mode = 0;
	}
	var ii = 0;
	if(String.fromCharCode(keynum) == "b"){
		if(canvasses[3].images != []){
			for(var i=0; i<canvasses[3].images.length; i++){
				var url = canvasses[3].images[0].src.replace(/^data:image\/[^;]+/, 'data:application/octet-stream');
				var a = window.document.createElement("a");
				a.href = url;
				a.download = Date.now()+".png";
				a.innerHTML = "image"+a.download;
				document.getElementById('download').appendChild(a);
				document.getElementById('download').appendChild(document.createElement("br"));
				//<a download="\'image"+Date.now()+".png\'" href="\'"+url+"\'">;//window.location.href = url;
				
				
				
        		var input = window.document.createElement("INPUT");
    			input.id = "in"+i++;
    			input.setAttribute("type", "file"); 
  		        document.getElementById('download').appendChild(input); 
			     
			     /*
				var button = window.document.createElement("button");
  		        button.onclick = function(e){
                    var xhr = new XMLHttpRequest();
                    xhr.open("POST", "/exist/projects/diae/collection/images/testor");
                    xhr.onloadend = function(e){
                        //The response of the upload
                        console.log("base64: "+xhr.responseText);
                        document.getElementById("log2").innerHTML = xhr.responseText;                       
                    }
                    var file = dataURLtoFile(url, "image"+Date.now()+".png");
                    //console.log(url.split(",")[1]);
	                var fd = new FormData();
                    fd.append("xt-photo-file", file);
                    //fd.append("fileName", "image"+Date.now()+".png");
                    console.log("fd "+file);
                    xhr.send(fd);//reader.readAsDataURL(file)
                    
                    var reader  = new FileReader();
                    var data;
                    reader.addEventListener("load", function () {
                        data = reader.result;
                        console.log("fda "+data);
                    }, false);
                    reader.readAsDataURL(file);
        		  
  			   }
            */  	   				
                    var button = window.document.createElement("button");
  		            button.onclick = function(e){
                    var xhr = new XMLHttpRequest();
                    xhr.open("POST", "/exist/projects/diae/collection/images/uploadZipCollection");
                    xhr.onloadend = function(e){
                        //The response of the upload
                        console.log(xhr.responseText);
                        document.getElementById("log2").innerHTML = xhr.responseText;                       
                    }
                    var file = document.getElementById('in0').files[0];
                    var reader  = new FileReader();
                    var data;
                    reader.addEventListener("load", function () {
                        data = reader.result;
                        data = 'data:application/octet-stream;' +data.split(";")[1];
                        var file = dataURLtoFile(data, "zip"+Date.now()+".zip");
                        //console.log(url.split(",")[1]);
    	                var fd = new FormData();
                        fd.append("zip-file", file);
                        //fd.append("fileName", "image"+Date.now()+".png");
                        console.log("fdb "+data);
                        xhr.send(fd);//reader.readAsDataURL(file)
                    }, false);
                    reader.readAsDataURL(file);
                    
  			       }
  			      
  			   document.getElementById('download').appendChild(button);
				/*
				var file = new File(url,"image"+Date.now()+".png")//dataURLtoFile(url, "image"+Date.now()+".png");
	            var fd = new FormData();
                fd.append("file", file);
                    var xhr = new XMLHttpRequest();
                    console.log("ready."+file.src);
                    xhr.open("POST", "/exist/projects/diae/selection/testing/images");
                    xhr.onloadend = function(e){
                        //The response of de upload
                        console.log("repsonse: "+xhr.responseText);
                        document.getElementById("log2").innerHTML =xhr.responseText;
    				}
    			*/

		  }
		  /*
  			var input = window.document.createElement("INPUT");
  			input.id = "in1";
  			input.setAttribute("type", "file"); 
			document.getElementById('download').appendChild(input);
  			var button = window.document.createElement("button");
  			button.onclick = function(e){
          		var file = document.getElementById("in1").files[0];
	            var fd = new FormData();
                fd.append("file.png", file);
                console.log("fd."+fd);
                var xhr = new XMLHttpRequest();
                console.log("ready."+file.size+"/"+file.type);
                xhr.open("POST", "/exist/projects/diae/persons/images");
                xhr.onloadend = function(e){
                    //The response of the upload
                    console.log("repsonse: "+xhr.responseText);
                    document.getElementById("log2").innerHTML =xhr.responseText;
        		}
        		xhr.send(fd);
  			    
  			}
			document.getElementById('download').appendChild(button);
			*/
		
	   }
        		
	}

	
	canvasses.forEach(function(wrapper){updateCanvas(wrapper)});
    console.log(String.fromCharCode(keynum));
});

function dataURLtoFile(dataurl, filename){
    var arr = dataurl.split(','), mime = arr[0].match(/:(.*?);/)[1],
        bstr = atob(arr[1]), n = bstr.length, u8arr = new Uint8Array(n);
    while(n--){
        u8arr[n] = bstr.charCodeAt(n);
    }
    return new File([u8arr], filename, {type:mime});
}
function _base64ToArrayBuffer(base64) {
    var binary_string =  window.atob(base64);
    var len = binary_string.length;
    var bytes = new Uint8Array( len );
    for (var i = 0; i < len; i++)        {
        bytes[i] = binary_string.charCodeAt(i);
    }
    return bytes.buffer;
}
var BASE64_MARKER = ';base64,';

function convertDataURIToBinary(dataURI) {
  var base64Index = dataURI.indexOf(BASE64_MARKER) + BASE64_MARKER.length;
  var base64 = dataURI.substring(base64Index);
  var raw = window.atob(base64);
  var rawLength = raw.length;
  var array = new Uint8Array(new ArrayBuffer(rawLength));

  for(i = 0; i < rawLength; i++) {
    array[i] = raw.charCodeAt(i);
  }
  return array;
}


var scrollTimer = 0;
function onScrolling(event){
	var x = event.clientX, y = event.clientY,
    canvas = document.elementFromPoint(x, y);
	var wrapper;
	for(index = 0; index < canvasses.length; ++index) {
		if(canvasses[index].canvas.id == canvas.id)
			wrapper =canvasses[index];
	}
	if (event.deltaY > 0) 
		wrapper.scale -= 0.1;
	if (event.deltaY < 0) 
		wrapper.scale += 0.1;
  
	//console.log('Scale '+wrapper.scale);
	document.getElementById('log').innerHTML = 'Scale '+wrapper.scale;
	updateCanvas(wrapper);
  //}
  //scrollTimer = Date.now(); 
}
var downleft = 0;
var downright = 0;
var downmiddle = 0;
var timestamp = 0;
var dragX = 0;
var dragY = 0;
var point = null;
var doubleclicktime= 0;
var doubleclick = 0;
var drawnewbox = 0;
var newPolygon;

var mouse;
function onMouseDown(event){
	var x = event.clientX, y = event.clientY,
    canvas = document.elementFromPoint(x, y);
	var pos = getMousePos(canvas,event); console.log(pos.x +" "+pos.y);
	mouse = pos;
	for(index = 0; index < canvasses.length; ++index) {
		if(canvasses[index].canvas.id == canvas.id){
			wrapper = canvasses[index];
		}
	}
	if(event.which == 1){//left click
		downleft = 1;
		if( wrapper.canvas.id == "view3"){
			boxes.forEach(function(polygon){
				t = polygon.pointAt(pos.translate(new Point(-wrapper.posX[0], -wrapper.posY[0])),wrapper);
				if(t !== -1)
					point = t;
			})
		}else if( wrapper.canvas.id == "view4"){
			var index = wrapper.pointOnWhichImage(pos);
			if(index != -1)
				wrapper.movingIndex = index;
		}
	}
	if(event.which == 2){//middle click
	   downmiddle = 1;
	}
	
	if(event.which == 3){//right click
		downright = 1;
		if( wrapper.canvas.id == "view3"){
			boxes.forEach(function(polygon){
				point = polygon.pointAt(pos.translate(new Point(-wrapper.posX[0], -wrapper.posY[0])),wrapper);
				if(point != -1){
					polygon.remove(point);	
				}else if(downleft){
					drawnewbox = 1;
					newPolygon = new Point(pos.x,pos.y);
				}					
			})
		}
		
	}
	
	//console.log(point);
	dragX = event.clientX;
	dragY = event.clientY;
	timestamp = Date.now();

 
}
function onMouseMove(event){
	var x = event.clientX, y = event.clientY,
    canvas = document.elementFromPoint(x, y);
	var pos = getMousePos(canvas,event); //console.log(pos.x +" "+pos.y);
	mouse = pos;
	var wrapper;
	for(index = 0; index < canvasses.length; ++index) {
		if(canvasses[index].canvas.id == canvas.id)
			wrapper = canvasses[index];
	}
	if(wrapper.canvas.id != "view4"){
		if(downleft === 1 && wrapper.mode == 1 && point != null){
			point.x += (event.clientX-dragX)*(1/wrapper.scale);
			point.y += (event.clientY-dragY)*(1/wrapper.scale);
			dragX = event.clientX;
			dragY = event.clientY;
		}
		
		if(downleft === 1 && wrapper.mode == 0 && (Date.now()-timestamp)>25){//mode == 0 means we are not moving boxes around
			wrapper.deltaX[0] -= event.clientX-dragX;
			wrapper.deltaY[0] -= event.clientY-dragY;
			dragX = event.clientX;
			dragY = event.clientY;
		}
		if(downright && downleft && drawnewbox == 1){
			//var t = newPolygon.multiply(wrapper.scale).translate(new Point(wrapper.posX[0],wrapper.posY[0]));			
			//var t2 = pos.multiply(wrapper.scale).translate(new Point(wrapper.posX[0],wrapper.posY[0]));		
			//canvas.getContext('2d').rect(t.x,t.y,t2.x,t2.y);
			//canvas.getContext('2d').stroke();
		}
	}
	
	if(wrapper.canvas.id == "view4"){		
		if(downleft === 1 && (Date.now()-timestamp)>25 &&wrapper.movingIndex != -1){
			
			wrapper.deltaX[wrapper.movingIndex] -= event.clientX-dragX;
			wrapper.deltaY[wrapper.movingIndex] -= event.clientY-dragY;
			dragX = event.clientX;
			dragY = event.clientY;
		}
	}
	updateCanvas(wrapper);
	
	timestamp = Date.now(); 

}
function onMouseUp(event){

	var x = event.clientX, y = event.clientY,
    canvas = document.elementFromPoint(x, y);
	var wrapper;
	for(index = 0; index < canvasses.length; ++index) {
		if(canvasses[index].canvas.id == canvas.id)
			wrapper = canvasses[index];
	}
	
	var pos = getMousePos(canvas,event); //console.log(pos.x +" "+pos.y);
	mouse = pos;
	var width = canvas.width;
	var height = canvas.height;
	if(doubleclicktime == 0){
        doubleclicktime =  Date.now();
    }else if((Date.now()-doubleclicktime)<500){
        doubleclick = 1;
        doubleclicktime = 0;
    }
	
	
	
    	
	
	if(event.which == 1 && downleft && doubleclick){//doubleclick
        doubleclick = 0;
        
	       console.log("double click");
	    
	}
	if(event.which == 1 && downleft){
        doubleclick = 0;
        
	       console.log("single click");
	    
	}
	
	if((event.which == 3 && downright) || (event.which == 1 && downleft)){
		if(drawnewbox){
			var t = newPolygon.translate(new Point(-wrapper.posX[0],-wrapper.posY[0])).multiply(1/wrapper.scale);			
			var t2 = mouse.translate(new Point(-wrapper.posX[0],-wrapper.posY[0])).multiply(1/wrapper.scale);		
		
			var poly = new Polygon();
			poly.addPoint(new Point(t.x,t.y));
			poly.addPoint(new Point(t2.x,t.y));
			poly.addPoint(new Point(t2.x,t2.y));
			poly.addPoint(new Point(t.x,t2.y));
			boxes.push(poly);
			drawnewbox = 0;
		}
	}

	
	if(event.which == 2 && downmiddle){
		if( wrapper.canvas.id == "view3"){
			boxes.forEach(function(polygon){
				point = polygon.pointAt(pos.translate(new Point(-wrapper.posX[0], -wrapper.posY[0])),wrapper);
				if(point != -1)
					polygon.split(point);
			})
			/*if(point == -1){
                var polygon = new Polygon();
        		var p = pos.translate(new Point(-wrapper.posX[0], -wrapper.posY[0])).multiply(1/wrapper.scale);
        		polygon.addPoint(p);
        		polygon.addPoint(new Point(p.x+200,p.y));
        		polygon.addPoint(new Point(p.x+200,p.y+50));
        		polygon.addPoint(new Point(p.x,p.y+50));
        		boxes.push(polygon);
			}*/
		}
	}
	
	if(down === 1){//TODO fix toolbar down not a var anymore
		if(pos.x < arrowSpacing && pos.x >= 0 && pos.y > 0 && pos.y < barWidth)//clicking on first arrow on toolbar (update when more buttons...)
			previousImage();
		if(pos.x < 2*arrowSpacing && pos.x >= arrowSpacing && pos.y > 0 && pos.y < barWidth)//clicking on seconf arrow on toolbar (update when more buttons...)
			nextImage();
			
		if(pos.x < 3*arrowSpacing && pos.x >= 2*arrowSpacing && pos.y > 0 && pos.y < barWidth)//clicking on third arrow on toolbar (update when more buttons...)
			previousCollection();
		if(pos.x < 4*arrowSpacing && pos.x >= 3*arrowSpacing && pos.y > 0 && pos.y < barWidth)//clicking on fourth arrow on toolbar (update when more buttons...)
			nextCollection();
			
		if(pos.x < width && pos.x >= width-arrowSpacing && pos.y > 0 && pos.y < barWidth)//clicking on last arrow on toolbar (update when more buttons...)
			scaleUp(wrapper);
		if(pos.x < width-3*arrowSpacing && pos.x >= width-4*arrowSpacing && pos.y > 0 && pos.y < barWidth)//clicking on second to last arrow on toolbar (update when more buttons...)
			scaleDown(wrapper);
	}
	wrapper.movingIndex = -1;
	dragX = 0;
    dragY = 0;
	downleft = 0;
	downright = 0;
	downmiddle = 0;
	point = null;
}
function getMousePos(canvas, event) {
    var rect = canvas.getBoundingClientRect();
    return new Point(event.clientX - rect.left, event.clientY - rect.top);
}

function Line(ctx){
    var me = this;
    
    this.x1 = 0;
    this.x2 = 0;
    this.y1 = 0;
    this.y2 = 0;
    
    this.draw = function(ctx) {
        ctx.beginPath();
        ctx.moveTo(me.x1, me.y1);
        ctx.lineTo(me.x2, me.y2);
        ctx.stroke();
    }
}


var barWidth = 20;
var arrowSpacing = 20;
function createToolbar(){
var ctx = canvasses[0].canvas.getContext('2d');
var width = canvasses[0].canvas.width;
var height = canvasses[0].canvas.height;

var line1 = new Line(ctx);
var line2 = new Line(ctx);
var line3 = new Line(ctx);
var line4 = new Line(ctx);
var line5 = new Line(ctx);
var line6 = new Line(ctx);
var line7 = new Line(ctx);
line1.x1 = arrowSpacing;
line1.y1 = 0;
line1.x2 = arrowSpacing;
line1.y1 = barWidth;
line2.x1 = 2*arrowSpacing;
line2.y1 = 0;
line2.x2 = 2*arrowSpacing;
line2.y1 = barWidth;

line3.x1 = width-4*arrowSpacing;
line3.y1 = 0;
line3.x2 = width-4*arrowSpacing;
line3.y1 = barWidth;
line4.x1 = width-3*arrowSpacing;
line4.y1 = 0;
line4.x2 = width-3*arrowSpacing;
line4.y1 = barWidth;
line5.x1 = width-arrowSpacing;
line5.y1 = 0;
line5.x2 = width-arrowSpacing;
line5.y1 = barWidth;

line6.x1 = 3*arrowSpacing;
line6.y1 = 0;
line6.x2 = 3*arrowSpacing;
line6.y1 = barWidth;
line7.x1 = 4*arrowSpacing;
line7.y1 = 0;
line7.x2 = 4*arrowSpacing;
line7.y1 = barWidth;
}