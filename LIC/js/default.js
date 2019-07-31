function displayDate(){
	document.getElementById("demo").innerHTML=Date();
}

function jumpto(anchor){
    window.location.href = "#"+anchor;
}

function initvars() {
var head_name = undefined;
var node_count = undefined;
var lcc_load = undefined;
var lcc_imgon = undefined;
var lcc_ulsc = undefined;
for (var i=1; i<100; i++)
	{ 
		window["node_name_" + i] = undefined;
	};
}

function dspvar() {
	{
		console.log(head_name);
		console.log(node_count);
		for (i = 1; i <= node_count; i++) {
			eval('console.log\(node_name_' + i + '\)');
		};
		console.log(lcc_load);
		console.log(lcc_imgon);
		console.log(lcc_ulsc);
	};
	setTimeout(dspvar, 500);
}


// function autoreload() {
// 	{
// 		// console.log(start_node_count);
// 		// console.log(node_count);
// 		if ( node_count !== start_node_count ) {
// 			// draw_nodes();
// 			console.log("ND refreshed! \nsnc="+start_node_count+"\n nc="+node_count);
// 		} else if ( node_count === 0 ){
// 			window.location.reload(true);
// 		}
// 	};
// 	setTimeout(autoreload,500);
// 	// console.log(" nc = "+node_count);
// 	// console.log("snc = "+start_node_count);
// }


// function wtcrtid() {
// 	for (var i=1; i<8; i++) {
// 		document.getElementById("id_node_name_"+crtnb+"_"+i).innerHTML = lcc_load[crtnb][i];
// 		console.log(lcc_load[crtnb][0]);
// 	};

// }

function wtallid() {
	document.getElementById("id_head_name").innerHTML = head_name;
	// document.getElementById("id_start_node_count").innerHTML = start_node_count;
	document.getElementById("id_node_count").innerHTML = node_count;
	for (var j=1; j<=node_count; j++) {
		var initnb = j
		for (var i=0; i<=8; i++) {
			document.getElementById("id_node_name_"+initnb+"_"+i).innerHTML = lcc_load[initnb][i];
			// console.log(lcc_load[initnb][0]);
			// document.getElementById("id_node_name_"+i+"_0").innerHTML = lcc_load[i][0];
		};
	}
}


function drop_child(tgt) {
	while (tgt.hasChildNodes()) {
		tgt.removeChild(tgt.lastChild);
	};
};

function node_ovscp(crtnb) {
	// var crtnb;
	var crtnode = "node_name_"+crtnb
	var actual_name = lcc_load[crtnb][0] ;
	console.log(crtnode);
	console.log(actual_name);
	var urdfPath = "/tmp/secrt.sitrep." + actual_name;
	console.log(urdfPath);
	document.getElementById("id_"+crtnode+"_0").innerHTML = actual_name;
}

function draw_nodes() {
	var tgt = document.getElementById("node_overview");
	drop_child(tgt);
	for ( i = 1; i<= node_count; i++) {
		// console.log ("node_name_"+i);
		var actual_name = lcc_load[i][0];
		// console.log(actual_name);
		var urdfPath = "/tmp/secrt.sitrep." + actual_name;
		// console.log(urdfPath);
		// console.log (tgt);
		// node_ovscp(i);
		var lb = document.createElement("BR");
		
		var Odiv=document.createElement("div");
		Odiv.id="node_ov_sub_"+i;
		Odiv.className="node-flex";
		// var content = document.createTextNode(actual_name);
		// Odiv.appendChild(content);
		var Idiv=document.createElement("div");
		Idiv.className="plant"
		Odiv.appendChild(Idiv);
		var Ih = document.createElement("H3");
		Ih.id = "id_node_name_"+i+"_0";
		Idiv.appendChild(Ih);
		var info_obj = {
			1 : "Load Rate: ",
			2 : "Perf Score: ",
			3 : "CPU % : ",
			4 : "\ IO % : ",
			5 : "USER : ",
			6 : "AR : ",
			7 : "Time stamp: ",
			8 : "LCC Lag: "
		};

		
		for ( k = 1; k <= 8; k++) {
			{
			var IP_k = document.createElement("P");
			var IP_kt = document.createTextNode(info_obj[k]);
			// console.log(info_obj[k]);
			// console.log(typeof IP_kt);
			// console.log(IP_kt);
			var IP_ko = document.createElement("OUTPUT");
			IP_ko.id = "id_node_name_"+i+"_"+k;
			// console.log(line);
			// console.log(line_o);
			// console.log(typeof IP_kt);
			IP_k.appendChild(IP_kt);
			IP_k.appendChild(IP_ko);
			// console.log(IP_[k]o.id);
			};
			Idiv.appendChild(IP_k);
		};
		tgt.appendChild(Odiv);
		
		// window.onload = function() {
		// 	var checker = i-1;
		// 	console.log(checker);
		// };
		// var checker = i;
		// console.log(checker);
	};
	function auto_redraw() {
		var checker = i - 1;
		console.log("checker   = " + checker);
		console.log("node_count= " + node_count);
		if ( checker !== node_count ) {
			// setTimeout('console.log("!!! REDRAW TRIGGERED !!!")', 3000);
			console.log("!!! REDRAW TRIGGERED !!!");
			draw_nodes();
		} else if (checker === node_count) {
			console.log("~ Cool, do nothing ~");
		};
	setTimeout(auto_redraw, 500);
	};
	// auto_redraw();
}

function urdf(file,optid) {
	var xmlHttp = null;
	// var xmlHttp = new XMLHttpRequest();
	if (window.ActiveXObject) {
		// IE6, IE5 浏览器执行代码
		xmlHttp = new ActiveXObject("Microsoft.XMLHTTP");
	} else if (window.XMLHttpRequest) {
		// IE7+, Firefox, Chrome, Opera, Safari 浏览器执行代码
		xmlHttp = new XMLHttpRequest();
	}
	if (xmlHttp != null) {
		xmlHttp.open("get", file, true);
		xmlHttp.send();
		xmlHttp.onreadystatechange = doResult; //设置回调函数                 
	}
	function doResult() {
		if (xmlHttp.readyState == 4) { //4表示执行完成
			if (xmlHttp.status == 200) { //200表示执行成功
				document.getElementById(optid).innerHTML = xmlHttp.responseText;
				// console.log(xmlHttp.responseText);
			}
		}
	}
	// setTimeout("urdf()",1000);
}

function uevf(file) {
	var xmlHttp_var = null;
	// var xmlHttp = new XMLHttpRequest();
	if (window.ActiveXObject) {
		// IE6, IE5 浏览器执行代码
		xmlHttp_var = new ActiveXObject("Microsoft.XMLHTTP");
	} else if (window.XMLHttpRequest) {
		// IE7+, Firefox, Chrome, Opera, Safari 浏览器执行代码
		xmlHttp_var = new XMLHttpRequest();
	}
	if (xmlHttp_var != null) {
		xmlHttp_var.open("get", file, true);
		xmlHttp_var.send();
		xmlHttp_var.onreadystatechange = doResult; //设置回调函数                 
	}
	function doResult() {
		if (xmlHttp_var.readyState == 4) { //4表示执行完成
			if (xmlHttp_var.status == 200) { //200表示执行成功
				// async :false,
				var readout = xmlHttp_var.responseText;
				// eval(xmlHttp_var.responseText);
				// console.log(node_count);
				// console.log(lcc_load);
				// console.log(lcc_imgon);
				// console.log(lcc_ulsc);
			};
		};
		console.log(typeof readout);
		// console.log(readout);
	}
	// setTimeout("urdf()",1000);
}

function txtop(name) {
	let xhr = new XMLHttpRequest(),
		okStatus = document.location.protocol === "file:" ? 0 : 200;
	xhr.open('GET', name, false);
	xhr.overrideMimeType("text/html; charset=utf-8");//默认为utf-8
	xhr.send(null);
	// console.log(typeof xhr.responseText);
	// console.log(xhr.responseText);
	return xhr.status === okStatus ? xhr.responseText : null;
}

function txteval(name) {
	let xhr = new XMLHttpRequest(),
		okStatus = document.location.protocol === "file:" ? 0 : 200;
	xhr.open('GET', name, false);
	xhr.overrideMimeType("text/html;charset=utf-8"); //默认为utf-8
	xhr.send(null);
	console.log(typeof xhr.responseText);
	console.log(xhr.responseText);
	return xhr.status === okStatus ? xhr.responseText : null;
}

function scpid(jscp,writeid) {
	var w;
	if(typeof(Worker) !== "undefined") {
		if(typeof(w) == "undefined") {
			w = new Worker(jscp);
		}
		w.onmessage = function(event) {
			document.getElementById(writeid).innerHTML = event.data;
		};
	} else {
		document.getElementById(writeid).innerHTML = "抱歉，你的浏览器不支持 Web Workers...";
	}
}

function scpeval(jscp) {
	var w = new Worker(jscp);;
	w.onmessage = function (event) {
		console.log(event.data);
		result.textContent = event.data;
		eval(event.data);
	};
}


function arrayToJson(o) {
	
    var r = [];
    if (typeof o == "string") return "\"" + o.replace(/([\'\"\\])/g, "\\$1").replace(/(\n)/g, "\\n").replace(/(\r)/g, "\\r").replace(/(\t)/g, "\\t") + "\"";
    if (typeof o == "object") {
      if (!o.sort) {
        for (var i in o)
        r.push(i + ":" + arrayToJson(o[i]));
        if (!!document.all && !/^\n?function\s*toString\s*\{\n?\s*\[native code\]\n?\s*\}\n?\s*$/.test(o.toString)) {
        r.push("toString:" + o.toString.toString());
        }
        r = "{" + r.join() + "}";
      } else {
        for (var i = 0; i < o.length; i++) {
        r.push(arrayToJson(o[i]));
        }
        r = "[" + r.join() + "]";
      }
      return r;
    }
    return o.toString();
  }



// window.onload=function () {
//         var Odiv=document.createElement("div");             //创建一个div
//         var Ospan=document.createElement("span");          //创建一个span
//         Odiv.style.cssText="width:200px;height:200px;background:#636363;
//         text-align:center;line-height:220px";    //创建div的css样式
//         //Odiv.id="box";                            //创建div的id为box
//         //Odiv.className="Box";                    //div的class为Box
//         Odiv.appendChild(Ospan);            //在div内创建一个span
//         document.body.appendChild(Odiv);        //在body内创建一个div
//
// 		var noApplicationRecord = document.getElementById('noApplicationRecord')
//
// //模拟数据
// var data = [
//     { business: '万达影院(万胜广场店)', count: '325', num: '20170012565863565656', time: '2017-10-12 16:30', license: '粤A88888' },
//     { business: '麦当劳', count: '111', num: '20170012565863565656', time: '2017-10-12 16:30', license: '粤A99999' },
//     { business: '肯德基', count: '456', num: '20170012565863565656', time: '2017-10-12 16:30', license: '粤A45466' }
// ]
// //绘制单个div
// function setDiv(item){
//     var div = '<div class="body-no-list"><div class="body-no-list-header" ><div class="body-no-list-header-title">'
//         + item.business
//         + '</div><div class="body-no-list-header-txt">消费金额:&nbsp;'
//         + item.count
//         + '元<br>消费单号:&nbsp;'
//         + item.num
//         + '<br>提交时间:&nbsp;'
//         + item.time
//         + '</div></div><div class="body-no-list-bottom"><div class="body-no-list-bottom-vehicl">'
//         + item.license
//         + '</div><div><button>撤销</button><button> 修改</button></div></div></div> '
//     return div
// }
// //循环加载到页面
// function getnoApplicationData(){
//     var html = ''
//     for(var i = 0;i<data.length;i++){
//         html += setDiv(data[i])
//     }
//     noApplicationRecord.innerHTML = html
// }
//
//  window.onload = getnoApplicationData()
//
//
//  <!DOCTYPE html>
// <html>
// <head lang="en">
//     <meta charset="UTF-8">
//     <title> 选项卡</title>
//     <style type="text/css">
//      /* CSS样式制作 */
//      *{padding:0px; margin:0px;}
//       a{ text-decoration:none; color:black;}
//       a:hover{text-decoration:none; color:#336699;}
//        #tab{width:270px; padding:5px;height:150px;margin:20px;}
//        #tab ul{list-style:none; display:;height:30px;line-height:30px; border-bottom:2px #C88 solid;}
//        #tab ul li{background:#FFF;cursor:pointer;float:left;list-style:none height:29px; line-height:29px;padding:0px 10px; margin:0px 10px; border:1px solid #BBB; border-bottom:2px solid #C88;}
//        #tab ul li.on{border-top:2px solid Saddlebrown; border-bottom:2px solid #FFF;}
//        #tab div{height:100px;width:250px; line-height:24px;border-top:none;  padding:1px; border:1px solid #336699;padding:10px;}
//        .hide{display:none;}
//     </style>
//
//     <scrIPT type="text/javascrIPT">
//     // JS实现选项卡切换
//     window.onload = function(){
//     var myTab = document.getElementById("tab");    //整个div
//     var myUl = myTab.getElementsByTagName("ul")[0];//一个节点
//     var myLi = myUl.getElementsByTagName("li");    //数组
//     var myDiv = myTab.getElementsByTagName("div"); //数组
//
//     for(var i = 0; i<myLi.length;i++){
//         myLi[i].index = i;
//         myLi[i].onclick = function(){
//             for(var j = 0; j < myLi.length; j++){
//                 myLi[j].className="off";
//                 myDiv[j].className = "hide";
//             }
//             this.className = "on";
//             myDiv[this.index].className = "show";
//         }
//       }
//     }
//     </scrIPT>
//
// </head>
// <body>
// <!-- HTML页面布局 -->
// <div id = "tab">
//         <ul>
//         <li class="off">房产</li>
//         <li class="on">家居</li>
//         <li class="off">二手房</li>
//         </ul>
//     <div id="firstPage" class="hide">
//             <a href = "#">275万购昌平邻铁三居 总价20万买一居</a><br/>
//             <a href = "#">200万内购五环三居 140万安家东三环</a><br/>
//             <a href = "#">北京首现零首付楼盘 53万购东5环50平</a><br/>
//             <a href = "#">京楼盘直降5000 中信府 公园楼王现房</a><br/>
//     </div>
//     <div id="secondPage" class="show">
//             <a href = "#">40平出租屋大改造 美少女的混搭小窝</a><br/>
//             <a href = "#">经典清新简欧爱家 90平老房焕发新生</a><br/>
//             <a href = "#">新中式的酷色温情 66平撞色活泼家居</a><br/>
//             <a href = "#">瓷砖就像选好老婆 卫生间烟道的设计</a><br/>
//     </div>
//     <div id="thirdPage" class = "hide">
//             <a href = "#">通州豪华3居260万 二环稀缺2居250w甩</a><br/>
//             <a href = "#">西3环通透2居290万 130万2居限量抢购</a><br/>
//             <a href = "#">黄城根小学学区仅260万 121平70万抛!</a><br/>
//             <a href = "#">独家别墅280万 苏州桥2居优惠价248万</a><br/>
//     </div>
// </div>
//
// </body>
// </html>
