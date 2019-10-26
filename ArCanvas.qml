import QtQuick 2.5
import QtQuick.Controls 1.4
import eplatplugins.qtdata 1.0
import "qrc:/component/qml/component/common/"
import "qrc:/component/qml/component/common/blue/"
import "qrc:/evss/qml/evss/armap/"
import "qrc:/js/qml/js/common/common.js" as CommonFun
import "qrc:/js/qml/js/common/navconfig.js" as NavConfig
import "qrc:/js/qml/js/evis/evisnavconfig.js" as EvisConfig
import "qrc:/js/qml/js/common/armapConfig.js" as ArConfig

Canvas {
    id: arCanvas;
    visible: true;
    signal zoomDraged(var mymouse);
    signal zoomDragPressed(var mymouse);
    signal zoomDragReleased(var mymouse);
    signal drawEnded(var msgShape);
    signal savedShapes(var shapeArr);
    signal selectEnded(string id);
    signal deleteEnded(string id);
    signal rightButtonOpr(string oprType,string id);//,string selectedType);
    signal changeRelatedScence(var devId);
    signal mobileLockStateChange(var id,var state);

    signal selectDevice(var msgDevId);
    signal doubleClickShow(var id);

    signal clickItem(var msgShape, var msgX, var msgY); //点击事件  双击
    // 鼠标形状属性
    property alias areaCursorShape: arArea.cursorShape;
    // 所有图像，包括直线和区域, 元素格式为： {id:"", type:"line", points:[], ...}
    property var shapeArray : new Array; //保存曲线、面多边形
    property ListModel shapeModel: ListModel{} //保存曲线 面多边形
     property ListModel mobileVisibleModel: ListModel{}

    property bool bMobileVideo: true //记录当前超视距平台显示的样式（是仅名称还是有播放）

    /* 重要：：model数据格式，缺一不可,不存在，赋默认值
    {
        "id": "",
        "name": "",
        "attribute": {},
        "layerId": "",
        "bVisible": false,
        "isDetailVisible": false,
        "layerData": {},
        "layerUserData": [],
        "alarmInfo": {},
        "relatedId": "",
        "devInfo": {},
        "geometry": {}，
        "bLocked":0
    }*/
    property ListModel textModel: ListModel{} //文本
    property ListModel imageModel: ListModel{} //图标
    property ListModel mobileModel: ListModel{} //执法仪
    // 当前选中图形的id
    property var currentIdx;
    // 当前选中图形 最后一个点的坐标值
    property var newRectCoords;
    // 画图中图形
    /*{
      "id":***,
      "selected": true/false,
      "geometry": {"type": "point/line/polygon/mark", "points":[[x,y], [x,y]]},
      "attribute": {"type": "text"/"image", ....}
    }*/
    property var targetShape;
    // 图形选中颜色
    property color defaultColor : "red";
    property color defaultFillColor: "lightgrey";
    property double defaultFillOpacity: 0.5; //默认透明度
    property color selectedColor: EvisConfig.ColorList.colorBgnNum1.textBlueColor;

    // 删除矩形框背景色 "#1691f4"
    property color deleteRecBg: EvisConfig.ColorList.colorBgnNum1.textBlueColor;
    // 节点颜色 #d5d5d5
    property color nodeColor: EvisConfig.ColorList.colorBgnNumOther.dataColor;
    // 字体大小
   // property int myFontSize: Math.floor(14 * scaleHeightFactor);
    property int myFontSize: NavConfig.FontList.fontSizeNormal;
    property int fontSizeSmall: NavConfig.FontList.fontSizeSmall;
    property int defaultFontSize: 14;
    property color dataColor: NavConfig.ColorList.blueColorList.textColor  //"#fff"
    property color selectedBgColor: NavConfig.ColorList.blueColorList.selected //"#f78d1c"
    // 字体
    property string fontFamily:"微软雅黑";
    property int leftMarg: 8 * scaleWidthFactor;
    // 选中图形ID
    property string selectedId;
    property int selectedShapeIdx: -1;
    // 线粗
    property real lineWidth: 2.0;
    // 选中线范围
    property real lineRange: 20.0;
    // 选中点范围
    property real pointRange: 20.0;

    property bool dragged: false;
    property bool isPointDragged: false;
    property real targetX;
    property real targetY;
    property real dragBeginX;
    property real dragBeginY;
    property real offsetX;
    property real offsetY;
    property int maxNums: 0;
    property var curDrawType: null;
    property var pressMark; //点击了标记按钮
    property var markShapeArr: new Array;//移动鼠标 记录标记移动的点

    //文字默认属性
    /*文字的对齐方式: 取值："center|end|left|right|start";
    (start:默认。文本在指定的位置开始;end:文本在指定的位置结束; center:文本的中心被放置在指定的位置;
    left:文本在指定的位置开始; right:文本在指定的位置结束)*/
    property var defaultTextAlign: "center";

    //文本的垂直基线：取值：alphabetic|top|hanging|middle|ideographic|bottom
     /*alphabetic	默认。文本基线是普通的字母基线。
        top	文本基线是 em 方框的顶端。
        hanging	文本基线是悬挂基线。
        middle	文本基线是 em 方框的正中。
        ideographic	文本基线是表意基线。
        bottom	文本基线是 em 方框的底端。*/
    property var defaultTextBaseline: "alphabetic";
    //font 属性使用的语法与 CSS font 属性 相同。
    property string defaultFont: "14px 微软雅黑";

//    property alias delMenuVis: deleteMenuRec.visible;
    property var drawTypeArray: ["point", "line", "polygon", "mark"]; //画图的类型
    property var attributeTypeArray: ["image", "text"]; //点元素的具体类型
    property bool bEditable: true; //图像是否可以修改

//    property var devConnectShapes: new Object;//点击视频时 存下当前点击视频的id值
    property var devId;//点击的视频的id值

    // 是否正在画
    property bool isDrawing: false;

    property int maxZ:1;


    function getSelectedDetail()
    {
    }


    //选中某个设备
    function selectImageItem(id)
    {
        var data = selectedModelItem(mobileModel, id);
        var data1 = selectedModelItem(imageModel, id);
        var data2 = selectedModelItem(shapeModel, id);
        var data3 = selectedModelItem(textModel, id);
        var oneInfo = !!data ? data : data1;

        if(!!oneInfo)
        {
            if(!!oneInfo.relatedId)
            {
                selectDevice(oneInfo.relatedId);
            }
            else
            {
                selectDevice(-1);
            }
        }
        else
        {
            selectDevice(null);
        }
    }


    //选中model中的某个元素，并返回选中的元素数据
    function selectedModelItem(model, id)
    {
        var selectedItem = null;
        for(var i = 0; i < model.count; i++)
        {
            if(id === model.get(i).id)
            {
                model.setProperty(i, "selected", true);
                selectedItem = model.get(i);

                //console.log(selectedItem.id,"selectedItem===============")
            }
            else
            {
                model.setProperty(i, "selected", false);
            }
        }
        return selectedItem;
    }

    //根据设备id，修改model中信息
    function editModelItem(devId,obj){
        if(!!imageModel && imageModel.count > 0){
            for(var i = 0;i< imageModel.count;i++){
                var oneInfo = imageModel.get(i);
                if(oneInfo.relatedId===devId){
                    imageModel.set(i,obj);

                }
            }
        }
        if(!!mobileModel && mobileModel.count > 0){
            for(var j = 0; j < mobileModel.count ;j++){
                var info = mobileModel.get(j);
                if(info.relatedId===devId){
                    mobileModel.set(j,obj);
                }
            }
        }
    }

    //获取路径


    function getVisibleCnt(){
        var cnt = 0;
        for(var i = 0;i < mobileModel.count;i++ ){

            var one = mobileModel.get(i);
            //console.log("get one bvisible",one.id,one.bVisible);
            if(mobileModel.get(i).bVisible){
                cnt++;
            }
        }
        return cnt;
    }

    function getVisibleModel(){
        mobileVisibleModel.clear();
        for(var i = 0;i < mobileModel.count;i++ ){

            var one = mobileModel.get(i);

            if(one.bVisible){
                mobileVisibleModel.append(one);
            }
        }
    }
    //控制超视距平台的按钮状态
    function controlBtn(){
         console.log("mobileView.currentIndex======,getVisibleCnt()",mobileView.currentIndex,getVisibleCnt());
        prevBtn.btnEnabled = mobileView.currentIndex > 0 ? true :false;
        nextBtn.btnEnabled = (mobileView.currentIndex +5 < getVisibleCnt()) ? true :false;
    }

    // 开始绘图
    function beginDraw(type, attribute)
    {
        var realId = maxNums++;
        targetShape = {};
        curDrawType = type;

        var typeTxtIdx = drawTypeArray.indexOf(type);
        if(typeTxtIdx == -1)
        {
            console.log("画图参数错误");
            return;
        }
        targetShape.attribute = attribute;
        if(!!attribute && attribute.id != undefined)
        {
            targetShape.id = attribute.id;
        }
        else
        {
            targetShape.id = drawTypeArray[typeTxtIdx] + (realId + 1);
        }

        targetShape.geometry = {"type": type, "points": []};
        targetShape.selected = false;
        isDrawing = true;
        arArea.cursorShape = Qt.CrossCursor;

        console.log(JSON.stringify(targetShape),"targetShape==============")
    }
    //增加显示元素
    function addItemsToCanvas(obj)
    {
        console.log(JSON.stringify(obj),"=====================obj id")
        obj.selected = false;
        obj.zIndex = maxZ++;
        if(!!obj.geometry&&obj.geometry.points!=undefined){
            if(obj.geometry.type == drawTypeArray[1] || obj.geometry.type == drawTypeArray[2]
                    || obj.geometry.type == drawTypeArray[3])
            {
                //shapeArray.push(obj);

                var curIconInfo1 = ArConfig.animateImg.animateImgs;
                curIconInfo1.forEach(function(values,i){
                    if(obj.geometry.type === values.type){
                        obj.imgNormal = values.image;
                        obj.imgDown = values.imageDown;
                    }
                });

                shapeModel.append(obj);
            }
            else if(obj.geometry.type == drawTypeArray[0])
            {
                var attr = obj.attribute;
                if(!!attr)
                {
                    if(attr.type == attributeTypeArray[0])
                    {

                        imageModel.append(obj);
//                        var data = imageModel.get(imageModel.count - 1);

                    }
                    else if(attr.type == attributeTypeArray[1])
                    {

                        var curIconInfo= ArConfig.animateImg.animateImgs;
                        curIconInfo.forEach(function(values,i){
                            if(obj.attribute.type === values.type){
                                obj.imgNormal = values.image;
                                obj.imgDown = values.imageDown;
                            }
                        });

                        textModel.append(obj);
//                        var data = textModel.get(textModel.count - 1);

                    }
                    else
                    {
                        console.log("输入的点属性类型不正确！");
                    }
                }
                else
                {
                    console.log("输入的点属性不存在！");
                }
            }
            else
            {
                console.log("输入的图形类型不正确！");
            }
        }
        else{
            //执法仪 移动设备后台不设置坐标xy
            //console.log("添加的是执法仪====");
            obj.select = false;
            obj.isDetailVisible = false;
            obj.bVisible = true;
            obj.bVideoVisible = bMobileVideo;
            mobileModel.append(obj);

//            console.log("mobileView.currentIndex=====",mobileView.currentIndex,nextBtn.btnEnabled);
//            if(!nextBtn.btnEnabled){
//               nextBtn.btnEnabled = true;
//            }

            controlBtn();

        }
    }

    //修改某个元素的显示
    function editCanvasItem(id, itemObj)
    {
       console.log("editCanvasItem==========",id,JSON.stringify(itemObj));

        if(!!itemObj.geometry && itemObj.geometry.points != undefined)
        {
            var type = itemObj.geometry.type;
            //console.log(JSON.stringify(itemObj),"itemObj=============")
            //console.log(type,"type===============")
            var idx = 0;
            switch(type)
            {
            case drawTypeArray[0]:
                //查找元素
                var attr = itemObj.attribute;
                //console.log(attr.type,attributeTypeArray[0],"type===========")
                if(attr.type == attributeTypeArray[0])
                {
                    //image
                    for(idx = 0; idx < imageModel.count; idx++)
                    {
                        if(imageModel.get(idx).id == id)
                        {

                            imageModel.set(idx, itemObj);
 //                           console.log("imageModel=======",JSON.stringify(imageModel.get(idx)));

                            break;
                        }
                    }
                }
                else if(attr.type == attributeTypeArray[1])
                {
                    for(idx = 0; idx < textModel.count; idx++)
                    {
                        if(textModel.get(idx).id == id)
                        {
                            textModel.set(idx, itemObj);
                            break;
                        }
                    }
                }
                else
                {
                    console.log("editCanvasItem 类型错误")
                }

                break;
            case drawTypeArray[1]:
            case drawTypeArray[2]:
            case drawTypeArray[3]:
                for(idx = 0; idx < shapeModel.count; idx++)
                {
                    if(shapeModel.get(idx).id == id)
                    {
                        shapeModel.set(idx, itemObj);
                    }
                }

                break;
            }
        }else
        {
            console.log("edit 超视距=============",id,JSON.stringify(itemObj))
            for(idx = 0; idx < mobileModel.count; idx++)
            {

                if(mobileModel.get(idx).id == id)
                {
                    mobileModel.set(idx, itemObj);
//                    mobileModel.set(idx, {"isDetailVisible": itemObj.isDetailVisible});
//                    console.log("mobileModel=======",mobileModel.get(idx).id);
                    break;
                }
            }
           // getVisibleModel();

            console.log("currentIndx=====",mobileView.currentIndex);
           // mobileView.currentIndex = 0;
            controlBtn();
        }
    }

    //将obj拷贝给修改数组中某个元素
    function setObjectToArrayData(data, obj)
    {
        for(var key in obj)
        {
            if(obj.hasOwnProperty(key) === true)
            {
                data[key] = obj[key];
            }
        }
    }

    function drawing()
    {
        requestPaint();
    }

    // 结束绘图
    function endDraw()
    {
        arArea.cursorShape = Qt.ArrowCursor;
        isDrawing = false;
        if(targetShape.geometry.type === drawTypeArray[2] || targetShape.geometry.type === drawTypeArray[3])
        {
            requestPaint();
        }
        drawEnded(targetShape);
    }

    // 删除图形
    function removeShape(id)
    {
         var idx = -1;
//         for(var i=0; i<shapeArray.length; i++)
//         {
//             if(id === shapeArray[i].id)
//             {
//                 idx = i;
//                 break;
//             }
//         }

        var findIdx = -1;
        for(idx = 0; idx < textModel.count; idx++)
        {
            if(textModel.get(idx).id == id)
            {
                textModel.remove(idx);
                findIdx = idx;
                break;
            }
        }
        if(findIdx == -1)
        {

            for(idx =0; idx < shapeModel.count; idx++)
            {
                if(shapeModel.get(idx).id == id)
                {
                    shapeModel.remove(idx);
                    requestPaint();
                    break;
                }
            }
        }

        if(findIdx == -1)
        {
            for(idx = 0; idx < imageModel.count; idx++)
            {
                if(imageModel.get(idx).id == id)
                {
                    imageModel.remove(idx);
                    break;
                }
            }
        }
        if(findIdx == -1)
        {
            for(idx = 0; idx < mobileModel.count; idx++)
            {
                if(mobileModel.get(idx).id == id)
                {
                    mobileModel.remove(idx);
                    mobileView.currentIndex = 0;//删除后回到第一个
                   // getVisibleModel();
                    break;
                }
            }
        }

    }

    // 选中图形
    function selectShape(x, y, id)
    {
        dragBeginX = x;
        dragBeginY = y;
        var curPoint = [x, y];
        var i,j;
//        for(i=0 ; i<shapeArray.length; i++ )
//        {
//            shapeArray[i].selected = false;
//            for(j = 0; j < shapeArray[i].geometry.points.length - 1; j++)
//            {
//                shapeArray[i].geometry.points[j].selected = false;
//            }
//            // shape的颜色恢复至最初的颜色
//            if(shapeArray[i].geometry.type !== drawTypeArray[2])
//            {
//                shapeArray[i].color = "red";
//            }
//            else
//            {
//                shapeArray[i].color = "orange";
//            }
//        }

        for(i = 0 ; i < shapeModel.count; i++)
        {
            //console.log(shapeModel.get(i).geometry.type,"geometry.type=========")
//            shapeModel.get(i).selected = false;
            var curType = shapeModel.get(i).geometry.type;
            //console.log(curType,"curType==============")
            shapeModel.set(i,{"selected": false});

            var psArr1 = [];
            var ps1;
            for(var kk = 0; kk < shapeModel.get(i).geometry.points.length; kk++)
            {
                ps1 = shapeModel.get(i).geometry.points[kk];
                psArr1.push(ps1);
            }

            for(j = 0; j < psArr1.length - 1; j++)
            {
                psArr1[j].selected = false;
            }

            // shape的颜色恢复至最初的颜色
            if(curType!== drawTypeArray[2])
            {
                //shapeModel.get(i).color = "red";
                shapeModel.set(i,{"color": "red"});
            }
            else
            {
                //shapeModel.get(i).color = "orange";
                shapeModel.set(i,{"color": "orange"});
            }
            //console.log(shapeModel.get(i).color,"color================")
        }

        isPointDragged = false;
        dragged = false;
        selectedId = "";
        selectedShapeIdx = -1;

        var ctx = getContext('2d');
        var isInLine = false;
        var shape, ps;
        if(id !== undefined && id !== "")
        {
//            for( i=0 ; i<shapeArray.length; i++ )
//            {
//                shape = shapeArray[i];
            for( i=0 ; i < shapeModel.count; i++ )
            {
                shape = shapeModel.get(i);
                var curId = shapeModel.get(i).id
                ps = shape.geometry.points;
                isInLine = false;
                if(curId === id)
                {
                    //shape.selected = true;
                    shapeModel.set(i,{"selected": true});
                    isInLine = true;
                    selectEnded(id);
                    break;
                }
            }
        }
        else
        {
            isInLine = false;
//            for( i=0 ; i<shapeArray.length; i++ )
//            {
//                shape = shapeArray[i];


            for( i=0 ; i < shapeModel.count; i++)
            {
                shape = shapeModel.get(i);
                var curType1 = shapeModel.get(i).geometry.type;
                //ps = shape.geometry.points;
                var curId1;
                //console.log(shapeModel.get(i).id,"shapeModel.get(i)========")

                var psArr = [];

                for(var k = 0; k < shapeModel.get(i).geometry.points.length; k++)
                {
                    ps = shapeModel.get(i).geometry.points[k];
                    psArr.push(ps);
                    //console.log(ps,"ps================")
                }

                //是否选中一个面多边形
                if(curType1 == drawTypeArray[2])
                {
                    var selected = isPointInPolygon(curPoint, psArr);
                    if(selected)
                    {
                        isInLine = true;
                        curId1 = shapeModel.get(i).id
                    }
                }
                else if(curType1 == drawTypeArray[1])
                {
                    for( j=0; j<psArr.length-1; j++ )
                    {
                        if(checkInLine(psArr[j][0], psArr[j][1], psArr[j+1][0], psArr[j+1][1], x, y, lineRange))
                        {
                            isInLine = true;
                            curId1 = shapeModel.get(i).id
                            break;
                        }
                    }
                }
                else if(curType1 == drawTypeArray[0])
                {
                    //点 text image不适用canvas
                }
                else if(curType1 == drawTypeArray[3])
                {
                    //todo-----这边需要分下情况 如果没有拖动 就约等于只有1个点(checkInPoint)
                    //标记 多个点 和checkInLine一样
                    for( j = 0; j < psArr.length - 1; j++)
                    {
                        if(checkInLine(psArr[j][0], psArr[j][1], psArr[j+1][0], psArr[j+1][1], x, y, lineRange))
                        {
                            isInLine = true;
                            curId1 = shapeModel.get(i).id
                            break;
                        }
                    }
                }

                if(isInLine)
                {
                    selectedShapeIdx = i;
                    selectedId = curId1;
                    console.log(selectedId,"selectedId===================")
                    selectEnded(selectedId);
                    if(bEditable)
                    {
//                        shape.selected = true;
//                        shape.color = selectedColor;

                        if(shapeModel.get(i).id == selectedId)
                        {
                            shapeModel.set(i,{"selected": true})
                            //shapeModel.set(i,{"color": selectedColor})
                        }

                        //dragged = true;
                        if(curType1 !== drawTypeArray[0])
                        {
                            for(j = 0; j < psArr.length; j++)
                            {
                                if(checkInPoint(psArr[j][0], psArr[j][1], x, y, pointRange))
                                {
                                    psArr[j].selected = true;
                                    isPointDragged = true;
                                    break;
                                }
                            }
                        }
                        requestPaint();
                    }

                    break;
                }
            }
        }

        return isInLine;
    }

    //z判断一个点是否在多边形内
    function isPointInPolygon(point, polygon)
    {
        var x = point[0], y = point[1];

        var inside = false;
        for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
            var xi = polygon[i][0], yi = polygon[i][1];
            var xj = polygon[j][0], yj = polygon[j][1];

            var intersect = ((yi > y) != (yj > y))
                && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
            if (intersect) inside = !inside;
        }

        return inside;
    }

    // 判断形状是否被选中
    function checkInLine(x1, y1, x2, y2, x, y, w)
    {
        var l = Math.sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2));
        var l1 = Math.sqrt((x1-x)*(x1-x) + (y1-y)*(y1-y));
        var l2 = Math.sqrt((x-x2)*(x-x2) + (y-y2)*(y-y2));
        var l3 = Math.sqrt(w*w + l*l);
        var h = Math.abs((y2-y1) * x + (x1-x2)*y-x1*y2+x2*y1) / Math.sqrt((y2-y1)*(y2-y1) + (x1-x2)*(x1-x2));

        if((l1 <= l3 && l2 <= l3 && h <= w) || (Math.abs(x1-x) <= w && Math.abs(y1-y) <= w) || (Math.abs(x2-x) <= w && Math.abs(y2-y) <= w))
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    // 判断点是否被选中
    function checkInPoint(x1, y1, x, y, d)
    {
        if(Math.abs(x1-x) <= d && Math.abs(y1-y) <= d)
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    function checkInImage(x1, y1, x, y, width, height)
    {
        return x >= x1 && x <= (x1 + width) && y >= y1 && y <= (y1 + height);
    }


    //取消画图
    function clearTrgShape()
    {
        targetShape = null;
    }

    //取消画图状态，未画完的删除
    function clearCanvasState()
    {
        isDrawing = false;
        targetShape = null;
        arCanvas.areaCursorShape = Qt.ArrowCursor;
    }

    //删除画布中所有shape,image,text
    function deleteAllLRComp()
    {
        console.log("删除画布中所有shape");
//        arCanvas.shapeArray = new Array;
        shapeModel.clear();
        arCanvas.requestPaint();

        imageModel.clear();
        textModel.clear();
        mobileModel.clear();
        editMenuRec.visible=false;
        bMobileVideo = true;
    }

    //画点（图标、文字）  废弃
    function paintPoint(ctx, points, attribute, bSelected)
    {
        if(points.length == 0)
        {
            return;
        }
        var left = points[0][0];
        var top = points[0][1];

        var type = "";
        if(!!attribute)
        {
            type = attribute.type;
            //图标
            if(type == "image")
            {
                if(!!attribute.icon && !!attribute.width && attribute.height && attribute.offset)
                {
                    ctx.drawImage(attribute.icon, left + attribute.offset.x, top + attribute.offset[1],
                                  attribute.width, attribute.height);
                }
                if(!!attribute.name)
                {

                }
            }
            else if(type == "text")
            {
                //文字
                var text = attribute.text;
                var font = defaultFont;
                if(!!attribute.font)
                {
                    font = "";
                    if(!!attribute.font.size)
                    {
                        font = attribute.font.size + "px";
                    }
                    if(!!attribute.font.family)
                    {
                        font += " " + attribute.font.family;
                    }
                    else
                    {
                        font += " 微软雅黑";
                    }
                }
//                console.log("font", font);

                var textAlign = !!attribute.textAlign ? attribute.textAlign : defaultTextAlign;
                var baseLine = !!attribute.textBaseline ? attribute.textBaseline : defaultTextBaseline;
                var color = !!attribute.color ? attribute.color : defaultColor;

                ctx.beginPath();
                ctx.textAlign = textAlign;
                ctx.font = font;
                ctx.textBaseline = baseLine;
                ctx.fillStyle = color;
                if(!!attribute.rotate)
                {
                    ctx.save();//保存画笔当前状态
                    ctx.translate(left, top);// 将画布的原点移动到正中央
                    ctx.rotate(attribute.rotate*Math.PI/180);
                    ctx.fillText(text , 0, 0);
                    ctx.restore();//复位画笔之前的状态
                }
                else
                {
                    ctx.fillText(text , left, top);
                }

                ctx.closePath();
            }
        }
    }

    //画线
    function paintPolyline(ctx, points, attribute, bSelected, offsetX, offsetY, shapeName)
    {
        var ox = offsetX;
        var oy = offsetY;
        var i = 0;
        if(points.length == 0)
        {
            return;
        }

        var polylineWidth = lineWidth;
        var lineColor = defaultColor;

        if(!!attribute)
        {
            if(attribute.lineWidth != undefined)
            {
                polylineWidth = attribute.lineWidth;
            }
            if(attribute.color != undefined)
            {
                lineColor = attribute.color;
            }
        }
        if(bSelected)
        {
            lineColor = NavConfig.ColorList.blueColorList.selected;//selectedColor;
        }

        //加上名称
//        if(shapeName)
//        {
//            ctx.font = defaultFont;
//            ctx.fillStyle = lineColor;
//            ctx.fillText(shapeName, points[0][0] - 5, points[0][1] - 5);
//        }

//        console.log("attribute", JSON.stringify(attribute), lineColor);
        ctx.beginPath();//开始新的路径
        ctx.moveTo(points[0][0] + ox, points[0][1] + oy);

        for(i = 1; i < points.length; i++)
        {
            ctx.lineTo(points[i][0] + ox, points[i][1] + oy);
        }
        ctx.lineWidth = polylineWidth;
        ctx.strokeStyle = lineColor;
        ctx.stroke();
        ctx.closePath();//关闭路径
        // 画出图形的所有点选中范围（半径为3的圆）
        if(bSelected)
        {
            ctx.beginPath();
            ctx.lineWidth = polylineWidth;
            ctx.globalAlpha = 1;
            ctx.strokeStyle = lineColor;
            ctx.fillStyle = nodeColor;
            for(i = 0; i < points.length; i++)
            {
                ctx.beginPath();
                //选中时增加显示节点圆
                ctx.arc(points[i][0] + ox, points[i][1] + oy, 3, 0, 2*Math.PI, true);
                ctx.stroke();
                ctx.fill();
                ctx.closePath();//关闭路径
            }
        }
    }

    //画多边形
    function paintPolygon(ctx, points, attribute, bSelected, offsetX, offsetY, shapeName)
    {
        var ox = offsetX;
        var oy = offsetY;
        var i = 0;
        if(points.length == 0)
        {
            return;
        }
        var polylineWidth = lineWidth;
        var lineColor = defaultColor;
        var fillColor = defaultFillColor;
        var fillOpacity = defaultFillOpacity;

        if(!!attribute)
        {
            if(attribute.lineWidth != undefined)
            {
                polylineWidth = attribute.lineWidth;
            }
            if(attribute.color != undefined)
            {
                lineColor = attribute.color;
            }
            if(attribute.fillColor != undefined)
            {
                fillColor = attribute.fillColor;
            }
            if(attribute.fillOpacity != undefined)
            {
                fillOpacity = attribute.fillOpacity;
            }
        }
        if(bSelected)
        {
            lineColor = NavConfig.ColorList.blueColorList.selected;//selectedColor;
            //fillColor = NavConfig.ColorList.blueColorList.selected
            //fillOpacity = 1
        }

//        //加上名称
//        if(shapeName)
//        {
//            ctx.font = defaultFont;
//            ctx.fillStyle = lineColor;
//            ctx.fillText(shapeName, points[0][0] - 10, points[0][1] - 10);
//        }

        ctx.beginPath();//开始新的路径
        ctx.moveTo(points[0][0] + ox, points[0][1] + oy);

        for(i = 1; i < points.length - 1; i++)
        {
            ctx.lineTo(points[i][0] + ox, points[i][1] + oy);
        }

        //封闭最后一个点成面
        i = points.length - 1;
        var xDis = points[i][0] - points[0][0];
        var yDis = points[i][1] - points[0][1];
        // 近似封闭
        if (xDis < 3 && xDis > -3 && yDis < 3 && yDis > -3)
        {
            ctx.lineTo(points[0][0] + ox, points[0][1] + oy);
        }
        // 严格封闭
        else if (points[i][0] === points[0][0] && points[i][1] === points[0][1])
        {
            ctx.lineTo(points[i][0] + ox, points[i][1] + oy);
        }
        // 不封闭，自动补线
        else
        {
            ctx.lineTo(points[i][0] + ox, points[i][1] + oy);
            ctx.lineTo(points[0][0] + ox, points[0][1] + oy);
        }

        ctx.lineWidth = polylineWidth;
        ctx.strokeStyle = lineColor;
        ctx.stroke();
        ctx.closePath();
        // 画出图形的所有点选中范围（半径为3的圆）
        if(bSelected)
        {
            ctx.globalAlpha = fillOpacity;
            ctx.fillStyle = fillColor;
            ctx.fill();

            ctx.beginPath();
            ctx.lineWidth = polylineWidth;
            ctx.globalAlpha = 1; //选中节点不透明
            ctx.strokeStyle = lineColor;
            ctx.fillStyle = nodeColor;
            for(i = 0; i < points.length; i++)
            {
                ctx.beginPath();
                //选中时增加显示节点圆
                ctx.arc(points[i][0] + ox, points[i][1] + oy, 3, 0, 2*Math.PI, true);

                ctx.stroke();
                ctx.fill();
                ctx.closePath();
            }
        }
        else
        {
            ctx.globalAlpha = fillOpacity;
            ctx.fillStyle = fillColor;
            ctx.fill();
        }
    }

    /**
     * 绘制带有箭头的直线
     * @param ctx画布变量
     * @param fromX/fromY 起点坐标
     * @param toX/toY 终点坐标
     * @param color 线与箭头颜色
    **/
    function drawLineArrow(ctx, points, attribute, bSelected, shapeName) {
//        var colorBg = defaultColor;
//        var color = defaultColor;

        var ox = offsetX;
        var oy = offsetY;

        var lineArrowWidth = lineWidth;
        var color = defaultColor;
        var fillColor = defaultFillColor;
        var fillOpacity = defaultFillOpacity;

        if(!!attribute)
        {
//            if(attribute.colorBg != undefined)
//            {
//                colorBg = attribute.colorBg;
//            }
//            if(attribute.color != undefined)
//            {
//                color = attribute.color;
//            }

            if(attribute.lineWidth != undefined)
            {
                lineArrowWidth = attribute.lineWidth;
            }
            if(attribute.color != undefined)
            {
                color = attribute.color;
            }
            if(attribute.fillColor != undefined)
            {
                fillColor = attribute.fillColor;
            }
            if(attribute.fillOpacity != undefined)
            {
                fillOpacity = attribute.fillOpacity;
            }
        }

        if(bSelected)
        {
            color = NavConfig.ColorList.blueColorList.selected//selectedColor;
            //fillColor = NavConfig.ColorList.blueColorList.selected
            //fillOpacity = 1
        }
        //console.log(JSON.stringify(points),"标记点位==============");
        if(points.length === 0)
        {
            return;
        }
        //fromX, fromY, toX, toY
        var i = 0;
        var fromX = points[0][0];
        var fromY = points[0][1];
        var toX,toY;

        if(points.length === 1){
            toX = fromX;
            toY = fromY;
        } else {
            for(i = 1; i < points.length; i++)
            {
                toX = points[i][0];
                toY = points[i][1];
            }
        }

        var headlen = 50;//自定义箭头线的长度
        var theta = 30;//自定义箭头线与直线的夹角
        var arrowX_top, arrowY_top, arrowX_bottom, arrowY_bottom;//箭头线终点坐标
        // 计算各角度和对应的箭头终点坐标(Math.atan2(y,x)得出的是弧度 再转为角度)
        var angle;
        if(fromX == toX && fromY == toY) {
            angle = 90; //AR页面中在一个点鼠标按下并抬起,呈90°
        } else {
            angle = Math.atan2(fromY - toY, fromX - toX) * 180 / Math.PI;
        }
        var angle1 = (angle + theta) * Math.PI / 180;
        var angle2 = (angle - theta) * Math.PI / 180;
        var topX = headlen * Math.cos(angle1);
        var topY = headlen * Math.sin(angle1);
        var botX = headlen * Math.cos(angle2);
        var botY = headlen * Math.sin(angle2);

        arrowX_top = toX + topX;
        arrowY_top = toY + topY;
        arrowX_bottom = toX + botX;
        arrowY_bottom = toY + botY;

        //中点坐标公式X=(X1+X2)/2  Y=(Y1+Y2)/2
        //已知点A(arrowX_top,arrowY_top);
        //已知点B(arrowX_bottom,arrowY_bottom);
        //设C为中点(middle_x,middle_y)
        var middle_c_x = (arrowX_top + arrowX_bottom) / 2;
        var middle_c_y = (arrowY_top + arrowY_bottom) / 2;

        // 设D为A,C中点(middle_d_x,middle_d_y)
        var middle_d_x = (arrowX_top + middle_c_x) / 2;
        var middle_d_y = (arrowY_top + middle_c_y) / 2;

        // 设E为B,C中点(middle_e_x,middle_e_y)
        var middle_e_x = (arrowX_bottom + middle_c_x) / 2;
        var middle_e_y = (arrowY_bottom + middle_c_y) / 2;

        //加上名称
//        if(shapeName)
//        {
////            console.log(shapeName.length,"shapeName==============")
////            if(shapeName.length > 10)
////            {
////                shapeName.substring(0,9);
////                  shapeName += "...";
////            }

//            ctx.font = defaultFont;
//            ctx.fillStyle = color;
//            ctx.fillText(shapeName, fromX - 10, fromY - 10);
//        }

        //以起始点为圆心 画半径为5的实心圆
        ctx.beginPath();
        ctx.arc(fromX, fromY, 5, 0, 2*Math.PI);
        ctx.strokeStyle = color;
        ctx.stroke();
        ctx.fillStyle = color;
        ctx.fill();

/**
        //虚线(中间那条长线)
        ctx.beginPath();
//        ctx.setLineDash([15, 5]);//虚线 ***************This method was introduced in QtQuick 2.11
        //画虚直线(画到了三角形和虚线交点处，不是画到头的)
        ctx.moveTo(fromX, fromY);
        ctx.lineTo(middle_c_x, middle_c_y);
//        ctx.strokeStyle = "rgb(130, 210, 210)";
        ctx.strokeStyle = color//"lightblue";//因为QtQuick 2.11 才支持虚线 先用不同色进行一个区分 看出效果
        ctx.stroke();
**/

        //实线(所有边线)
        ctx.beginPath();
        ctx.lineWidth = lineArrowWidth;
//        ctx.setLineDash([]);//实线 *******************This method was introduced in QtQuick 2.11
        //画上边箭头线
        ctx.moveTo(toX, toY);
        ctx.lineTo(arrowX_top, arrowY_top);//上箭头坐标
        ctx.lineTo(middle_d_x, middle_d_y);//上箭头中间点坐标
        ctx.lineTo(fromX, fromY);
        //画下边箭头线
        ctx.lineTo(middle_e_x, middle_e_y);//下箭头中间点坐标
        ctx.lineTo(arrowX_bottom, arrowY_bottom);//下箭头坐标
        ctx.lineTo(toX, toY);
        ctx.strokeStyle = color;
        ctx.stroke();

        // 画出图形的所有点选中范围（半径为3的圆）
        if(bSelected)
        {
            ctx.globalAlpha = fillOpacity;
            ctx.fillStyle = fillColor;
            ctx.fill();

            ctx.beginPath();
            ctx.lineWidth = lineArrowWidth;
            ctx.globalAlpha = 1; //选中节点不透明
            ctx.strokeStyle = color;
            ctx.fillStyle = nodeColor;

            //选中时增加显示节点圆
            ctx.arc(fromX + ox, fromY + oy, 3, 0, 2*Math.PI, true);
            ctx.stroke();
            ctx.fill();
            ctx.closePath();

//            ctx.beginPath();
//            ctx.arc(middle_d_x + ox, middle_d_y + oy, 3, 0, 2*Math.PI, true)
//            ctx.stroke();
//            ctx.fill();
//            ctx.closePath();

            ctx.beginPath();
            ctx.arc(arrowX_top + ox, arrowY_top + oy, 3, 0, 2*Math.PI, true)
            ctx.stroke();
            ctx.fill();
            ctx.closePath();

            ctx.beginPath();
            ctx.arc(toX + ox, toY + oy, 3, 0, 2*Math.PI, true)
            ctx.stroke();
            ctx.fill();
            ctx.closePath();

            ctx.beginPath();
            ctx.arc(arrowX_bottom + ox, arrowY_bottom + oy, 3, 0, 2*Math.PI, true)
            ctx.stroke();
            ctx.fill();
            ctx.closePath();

//            ctx.beginPath();
//            ctx.arc(middle_e_x + ox, middle_e_y + oy, 3, 0, 2*Math.PI, true)
//            ctx.stroke();
//            ctx.fill();
//            ctx.closePath();
        }
        else
        {
            ctx.globalAlpha = fillOpacity;
            ctx.fillStyle = fillColor;
            ctx.fill();
        }
    }

    onPaint: {
        var ctx = getContext('2d');
        ctx.reset();
        ctx.lineWidth = lineWidth;

        //ctx.strokeRect(5,5,arCanvas.width-10,arCanvas.height-10);
        var firstPoint = true;
        var ps;
        var i;
        var ox, oy;
        //console.log(JSON.stringify(shapeArray),"shapeArray=====>");
//        for(var o in shapeArray)
//        {
//            var curShape = shapeArray[o];

        for(var o = 0; o < shapeModel.count; o++)
        {
            //console.log("jinlaikkkkkkkkkkkkkk=================")
            var curShape = shapeModel.get(o);
            if(!curShape.bVisible)
            {
                continue;
            }

            //console.log(shapeModel.get(o).id,"curShape=====================")
            var psArr = [];

            ctx.beginPath();
            ctx.lineWidth = lineWidth;
            ctx.globalAlpha = 1;
//            ctx.strokeStyle = curShape.selected ? selectedColor : curShape.color;
            ctx.strokeStyle = JSON.stringify(shapeModel.get(o).attribute.color);

            for(var k = 0; k < shapeModel.get(o).geometry.points.length; k++)
            {
                ps = shapeModel.get(o).geometry.points[k];
                psArr.push(ps);
                //console.log(ps,"ps================")
            }

            //ps = shapeModel.get(o).geometry.points;
            //console.log(JSON.stringify(ps),"curShape.geometry.points1")

            if(shapeModel.get(o).selected && !isPointDragged)
            {
                ox = offsetX;
                oy = offsetY;
            }
            else
            {
                ox = 0;
                oy = 0;
            }
            ctx.moveTo(psArr[0][0] + ox, psArr[0][1] + oy);

            var curType = shapeModel.get(o).geometry.type;
            //console.log(curType,"curType===================")

            var attribute1 = JSON.stringify(shapeModel.get(o).attribute)

            //画点
            if(shapeModel.get(o).geometry.type == drawTypeArray[0])
            {
//                paintPoint(ctx, shapeModel.get(o).geometry.points, shapeModel.get(o).attribute, shapeModel.get(o).selected);
            }
            else if(shapeModel.get(o).geometry.type == drawTypeArray[1])
            {
                paintPolyline(ctx, psArr, shapeModel.get(o).attribute, shapeModel.get(o).shapeSelected, ox, oy, shapeModel.get(o).name);
            }
            else if(shapeModel.get(o).geometry.type == drawTypeArray[2])
            {
                paintPolygon(ctx, psArr, shapeModel.get(o).attribute, shapeModel.get(o).shapeSelected, ox, oy, shapeModel.get(o).name);
            }
            else if(shapeModel.get(o).geometry.type == drawTypeArray[3])
            {
                drawLineArrow(ctx, psArr, shapeModel.get(o).attribute, shapeModel.get(o).shapeSelected, ox, oy,shapeModel.get(o).name);
            }
        }

        if(targetShape !== null && arCanvas.targetShape !== undefined)
        {
            //console.log("jinlailllllll=================")
            ps = targetShape.geometry.points;
            //console.log(JSON.stringify(ps),"curShape.geometry.points2")
            if(ps.length > 0)
            {
                var polylineWidth = lineWidth;
                var lineColor = defaultColor;
                var fillColor = defaultFillColor;
                var fillOpacity = defaultFillOpacity;

                var attribute = targetShape.attribute;
                if(!!attribute)
                {
                    if(attribute.lineWidth != undefined)
                    {
                        polylineWidth = attribute.lineWidth;
                    }
                    if(attribute.color != undefined)
                    {
                        lineColor = attribute.color;
                    }
                    if(attribute.fillColor != undefined)
                    {
                        fillColor = attribute.fillColor;
                    }
                    if(attribute.fillOpacity != undefined)
                    {
                        fillOpacity = attribute.fillOpacity;
                    }
                }

                ctx.beginPath();
                ctx.lineWidth = polylineWidth;
                ctx.globalAlpha = 1; //选中节点不透明
                ctx.strokeStyle = lineColor;
                firstPoint = true;

                if(targetShape.geometry.type !== drawTypeArray[0] && targetShape.geometry.type !== drawTypeArray[3])
                {
                    for(i = 0; i < ps.length; i++)
                    {
                        if(firstPoint)
                        {
                            firstPoint = false;
                            ctx.moveTo(ps[i][0], ps[i][1]);
                        } else
                        {
                            ctx.lineTo(ps[i][0], ps[i][1]);
                        }
                    }
                    ctx.lineTo(targetX, targetY);
                    ctx.stroke();
                    if(targetShape.geometry.type === drawTypeArray[2])
                    {
                        if(!isDrawing)
                        {
                            //封闭最后一个点成面
                            i = ps.length - 1;
                            var xDis = ps[i][0] - ps[0][0];
                            var yDis = ps[i][1] - ps[0][1];
                            // 近似封闭
                            if (xDis < 3 && xDis > -3 && yDis < 3 && yDis > -3)
                            {
                                ctx.lineTo(ps[0][0] + ox, ps[0][1] + oy);
                            }
                            // 严格封闭
                            else if (ps[i][0] === ps[0][0] && ps[i][1] === ps[0][1])
                            {
                                ctx.lineTo(ps[i][0] + ox, ps[i][1] + oy);
                            }
                            // 不封闭，自动补线
                            else
                            {
                                ctx.lineTo(ps[i][0] + ox, ps[i][1] + oy);
                                ctx.lineTo(ps[0][0] + ox, ps[0][1] + oy);
                            }

                            ctx.lineWidth = polylineWidth;
                            ctx.strokeStyle = lineColor;
                            ctx.stroke();
                        }

                        ctx.globalAlpha = fillOpacity;
                        ctx.fillStyle = fillColor;
                        ctx.fill();
                    }
                    ctx.closePath();
                }
            }
            //这边是为了跟着鼠标按下一直画 标记箭头
            var ps2 = arCanvas.markShapeArr;
            if(ps2.length > 0)
            {
                if(targetShape.geometry.type === drawTypeArray[3])
                {
                    drawLineArrow(ctx, ps2, targetShape.attribute);
                }
            }
        }
    }

    MouseArea {
        id: arArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.ArrowCursor;
        z:isDrawing? maxZ + 1 : 0
        //鼠标透传，否则影响审看页面的播放器A的选中
        propagateComposedEvents: true;
        onClicked: {
            mouse.accepted = false;
        }

        onPressed: {
//            deleteMenuRec.visible = false;
            editMenuRec.visible = false;
            // 画图进行中
            if(isDrawing && arCanvas.targetShape !== null && arCanvas.targetShape !== undefined)
            {
                // 左键，画图开始
                if (mouse.button == Qt.LeftButton)
                {
                    if(arCanvas.targetShape.geometry.type === drawTypeArray[3]){
                        pressMark = true;
                        arCanvas.targetShape.geometry.points.push([mouseX, mouseY]);
                        arCanvas.markShapeArr.push([mouseX, mouseY]);
                        return;
                    }

                    if(arCanvas.targetShape.geometry.points.length === 0)
                    {
                        arCanvas.targetShape.geometry.points.push([mouseX, mouseY]);
                    }
                    else if (arCanvas.targetShape.geometry.type !== drawTypeArray[0])//点位 只有一个坐标
                    {
                        var idx = arCanvas.targetShape.geometry.points.length - 1;
                        if(arCanvas.targetShape.geometry.points[idx][0] !== mouseX && arCanvas.targetShape.geometry.points[idx][1] !== mouseY)
                        {
                            arCanvas.targetShape.geometry.points.push([mouseX, mouseY]);
                        }
                    }

                    if(curDrawType == drawTypeArray[0])
                    {
                        arCanvas.endDraw();
                    }
                }
                else
                {
                    //右键取消画图
                    clearCanvasState();
                    requestPaint();
                }
            }
            else
            {
//                // 其他操作
                if(mouse.button == Qt.LeftButton)
                {
//                    //拖动选中图形
//                    var selectedFlag = arCanvas.selectShape(mouseX, mouseY, "");
//                    if(selectedFlag && selectedShapeIdx != -1)
//                    {
//                        //clickItem(shapeArray[selectedShapeIdx], mouseX, mouseY);
//                        clickItem(shapeModel.get(selectedShapeIdx), mouseX, mouseY);
                        //console.log(selectedId,"2selectedId=====================")
//                    }

//                    //不选中任何设备
                    selectImageItem(-1);

//                    //arCanvas.dragged = true;
                }
                else if(mouse.button == Qt.RightButton)
                {
//                    //右键菜单-删除/详情/弹出框
//                    //菜单显示
//                    if(arCanvas.selectShape(mouseX, mouseY, ""))
//                    {
//                        editMenuRec.visible = true;
//                        editMenuRec.x = mouseX// + 50;
//                        editMenuRec.y = mouseY;
//                    }
                }
            }
        }
        onReleased:
        {
            arArea.cursorShape = Qt.ArrowCursor;
            //整体移动的时候没有修改shapeArray的值，移动结束后才修改
            //拖拽某个点时实时修改了shapeArray中的值

            if(curDrawType == drawTypeArray[3] && pressMark)
            {
                arCanvas.targetShape.geometry.points.push([mouseX, mouseY]);
                arCanvas.markShapeArr.push([mouseX, mouseY]);
                pressMark = false;
                arCanvas.endDraw();//因为标记箭头是鼠标按下-移动-抬起 过程就结束了
                return;
            }

//            if(selectedShapeIdx != -1 && arCanvas.shapeArray[selectedShapeIdx].selected && !arCanvas.isPointDragged)
//            {
//                for(var j=0; j<arCanvas.shapeArray[selectedShapeIdx].geometry.points.length; j++)
//                {
//                    arCanvas.shapeArray[selectedShapeIdx].geometry.points[j][0] += arCanvas.offsetX;
//                    arCanvas.shapeArray[selectedShapeIdx].geometry.points[j][1] += arCanvas.offsetY;
//                }
//            }

            if(selectedShapeIdx != -1 && arCanvas.shapeModel.get(selectedShapeIdx).selected && !arCanvas.isPointDragged)
            {
                for(var j=0; j<shapeModel.get(selectedShapeIdx).geometry.points.length; j++)
                {
                    shapeModel.get(selectedShapeIdx).geometry.points[j][0] += arCanvas.offsetX;
                    shapeModel.get(selectedShapeIdx).geometry.points[j][1] += arCanvas.offsetY;
                }
            }

            arCanvas.dragged = false;
            arCanvas.offsetX = 0;
            arCanvas.offsetY = 0;
            arCanvas.isPointDragged = false;
            arCanvas.drawing();
        }
        onDoubleClicked: {
            mouse.accepted = false;
            //console.log("commoncavas doubleClick====")
            if(mouse.button === Qt.LeftButton)
            {
                if(isDrawing && arCanvas.targetShape !== null && arCanvas.targetShape !== undefined)
                {
                    if(arCanvas.targetShape.geometry.type === drawTypeArray[1])//画直线 双击即可结束
                    {
                        arCanvas.endDraw();
                    }
                    else if(arCanvas.targetShape.geometry.type === drawTypeArray[2]
                            && arCanvas.targetShape.geometry.points.length >= 3)//画多边形 点>=3可以结束
                    {
                        // 画ROI结束
                        arCanvas.endDraw();
                    }
                    else if(arCanvas.targetShape.geometry.type === drawTypeArray[0]
                            && arCanvas.targetShape.geometry.points.length === 1)
                    {
                        arCanvas.endDraw();
                    }
                }
            }
            else
            {
                console.log("鼠标的其他按键的双击不做任何动作");
            }
        }

        onPositionChanged: {
            var i,j;
            // 画图进行中
            zoomDraged(mouse);  //做了鼠标形状变化，用到时请注意

            if(isDrawing && arCanvas.targetShape !== null && arCanvas.targetShape !== undefined) {
                arCanvas.targetX = mouseX;
                arCanvas.targetY = mouseY;
                if(arCanvas.targetShape.geometry.type === drawTypeArray[3])
                {
                    if(pressMark){
                       arCanvas.markShapeArr.push([mouseX, mouseY]);
                    }

                }
                arCanvas.drawing();
            }
            else
            {
                if(arCanvas.dragged)
                {
                    if(!arCanvas.isPointDragged){
                        arArea.cursorShape = Qt.SizeAllCursor;
                    }
                    else
                    {
                        arArea.cursorShape = Qt.ArrowCursor;
                    }

                    //var curShape = arCanvas.shapeArray[selectedShapeIdx];
                    var curShape = arCanvas.shapeModel.get(selectedShapeIdx);

                    if(arCanvas.isPointDragged)
                    {
                        for(j=0; j < curShape.geometry.points.length; j++)
                        {
                            if(curShape.geometry.points[j].selected)
                            {
                                var newspx, newspy;
                                newspx = mouseX;
                                newspy = mouseY;
                                if(newspx < 0)
                                {
                                   newspx = 0;
                                } else if (newspx > arCanvas.width)
                                {
                                    newspx = arCanvas.width;
                                }
                                if(newspy < 0)
                                {
                                   newspy = 0;
                                } else if (newspy > arCanvas.height)
                                {
                                    newspy = arCanvas.height;
                                }
                                curShape.geometry.points[j][0] = newspx;
                                curShape.geometry.points[j][1] = newspy;
                                break;
                            }
                        }
                    }
                    else
                    {
                        arCanvas.offsetX = mouseX - arCanvas.dragBeginX;
                        arCanvas.offsetY = mouseY - arCanvas.dragBeginY;
                        if(arCanvas.offsetX < 0)
                        {
                            var minX;
                            minX = curShape.geometry.points[0][0]
                            for(j=1; j < curShape.geometry.points.length; j++)
                            {
                                if(curShape.geometry.points[j][0] < minX)
                                {
                                    minX = curShape.geometry.points[j][0];
                                }
                            }
                            if(minX + arCanvas.offsetX < 0)
                            {
                                arCanvas.offsetX = -minX;
                            }
                        }
                        if(arCanvas.offsetY < 0)
                        {
                            var minY;
                            minY = curShape.geometry.points[0][1];
                            for(j=1; j < curShape.geometry.points.length; j++)
                            {
                                if(curShape.geometry.points[j][1] < minY)
                                {
                                    minY = curShape.geometry.points[j][1];
                                }
                            }
                            if(minY + arCanvas.offsetY < 0)
                            {
                                arCanvas.offsetY = -minY;
                            }
                        }
                        if(arCanvas.offsetX > 0)
                        {
                            var maxX= curShape.geometry.points[0][0];
                            for(j=1; j<curShape.geometry.points.length; j++)
                            {
                                if(curShape.geometry.points[j][0] > maxX)
                                {
                                    maxX = curShape.geometry.points[j][0];
                                }
                            }
                            if(arCanvas.offsetX + maxX > arCanvas.width)
                            {
                                arCanvas.offsetX = arCanvas.width - maxX;
                            }
                        }
                        if(arCanvas.offsetY > 0)
                        {
                            var maxY = curShape.geometry.points[0][1]
                            for(j=1; j < curShape.geometry.points.length; j++)
                            {
                                if(curShape.geometry.points[j][1] > maxY)
                                {
                                    maxY = curShape.geometry.points[j][1];
                                }
                            }
                            if(arCanvas.offsetY + maxY > arCanvas.height)
                            {
                                arCanvas.offsetY = arCanvas.height - maxY;
                            }
                        }
                    }

                    arCanvas.drawing();
                }
            }
        }
    }

    Rectangle{
        id: iamgeRect
        anchors.fill: parent
        color: "transparent"
        //设备兴趣点
        Repeater{
            model: imageModel
            Rectangle{
                id:pointRect;
                width:ArConfig.armapList.arDevPointList[0].width//model.attribute.width
                height:ArConfig.armapList.arDevPointList[0].height//model.attribute.height
                color:"transparent";
                visible: model.bVisible
                z: model.zIndex
                Rectangle{
                    id: imageRect
                    property string id: model.id
                    x: model.geometry.points[0][0] + ArConfig.armapList.arDevPointList[0].offsetX
                    y: model.geometry.points[0][1] + ArConfig.armapList.arDevPointList[0].offsetY
                    width: ArConfig.armapList.arDevPointList[0].width
                    height: ArConfig.armapList.arDevPointList[0].height
                    color:"transparent"
                    //精灵动画
                    AnimatedSprite {
                        id: animateImg
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        source: model.selected ? ArConfig.armapList.arDevPointList[0].anim_dow : ArConfig.armapList.arDevPointList[0].anim_nor
                        width: 30
                        height: 30
                        frameWidth: 30
                        frameHeight: 30
                        frameDuration: 200
                        frameCount: 9
                        frameX: 0
                        frameY: 0
                        loops: Animation.Infinite
                        running: true
                        onVisibleChanged: {
                            if(visible)
                            {
                                animateImg.restart();
                            }
                        }

                        z: 2
                        MouseArea{
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            hoverEnabled: true
                            cursorShape: Qt.ArrowCursor;
                            propagateComposedEvents: true; //鼠标透传
                            onClicked: {
                                model.zIndex = maxZ++;
                                //console.log("maxZ=================",maxZ);
                                selectedId = model.id;
                                selectedShapeIdx = -1;
                                if(mouse.button == Qt.LeftButton)
                                {
                                    selectImageItem(selectedId);
                                    model.isDetailVisible= !model.isDetailVisible;
                                }
                                else
                                {
                                    //右键菜单-删除/详情/弹出框
                                    editMenuRec.visible = true;
                                    editMenuRec.parent = arCanvas;
                                    editMenuRec.x = imageRect.x + mouseX+20;
                                    editMenuRec.y = imageRect.y + mouseY+10;
                                }
                            }
                            onDoubleClicked: {
                                console.log("imageRect double click=======");
                                selectedId = model.id;
                                selectedShapeIdx = -1;
                                if(mouse.button == Qt.LeftButton)
                                {
                                    selectImageItem(selectedId);
                                    clickItem(model,imageRect.x + mouseX,imageRect.y + mouseY);

                                }

                            }
                        }
                    }

                    //连线
                    Line{
                        id:line1
                        point1: Qt.point(animateImg.width / 2, imageRect.height - animateImg.height / 2)
                        point2: Qt.point(nameRect.anchors.leftMargin + 2, nameRect.height - 3)
                        lineWidth: 1
                        lineColor: model.selected ? ArConfig.armapList.arDevPointList[0].dev_line_dow.bg
                                                  : ArConfig.armapList.arDevPointList[0].dev_line_nor.bg
                        borderColor: model.selected ? ArConfig.armapList.arDevPointList[0].dev_line_dow.border
                                                    : ArConfig.armapList.arDevPointList[0].dev_line_nor.border
                        z:1
                    }
                    //设备名称区域
                    Rectangle{
                        id: nameRect
                        anchors.left: parent.left
                        anchors.leftMargin: 68
                        anchors.top: parent.top
                        width: 201
                        height: 38
                        color: "transparent"
                        z: line1.z + 1
                        MouseArea{
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            hoverEnabled: true
                            cursorShape: Qt.ArrowCursor;
                            propagateComposedEvents: true; //鼠标透传
                            onClicked: {
                                console.log("isDrawing============",isDrawing);
                                model.zIndex = maxZ++;
                                selectedId = model.id;
                                selectedShapeIdx = -1;
                                if(mouse.button == Qt.LeftButton)
                                {
                                    selectImageItem(selectedId);
                                    model.isDetailVisible= !model.isDetailVisible;
                                }
                                else
                                {
                                    //右键菜单-删除/详情/弹出框
                                    editMenuRec.visible = true;
                                     editMenuRec.parent = arCanvas;
                                    editMenuRec.x = imageRect.x + mouseX+20;
                                    editMenuRec.y = imageRect.y + mouseY+10;

                                }
                            }
                            onDoubleClicked: {
                               // console.log("imageRect double click=======");
                                selectedId = model.id;
                                selectedShapeIdx = -1;
                                if(mouse.button == Qt.LeftButton)
                                {
                                    selectImageItem(selectedId);
                                    clickItem(model,imageRect.x + mouseX,imageRect.y + mouseY);

                                }

                            }
                        }
                        Image{
                            anchors.fill: parent
                            source: model.selected ? ArConfig.armapList.arDevPointList[0].dev_title_bg_dow
                                                   : ArConfig.armapList.arDevPointList[0].dev_title_bg
                        }

                        Image{
                            id:typeIcon;
                            anchors.left: parent.left
                            anchors.leftMargin: leftMarg
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            height: 20
                            source: model.attribute.typeIcon;
                        }

                        TextWithTips{
                            id:titleName;
                            anchors.left: typeIcon.right
                            anchors.leftMargin: leftMarg
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.rightMargin: 38
                            myTextColor: dataColor;//NavConfig.ColorList.blueColorList.textColor
                            //                            width:130;
                            height:parent.height - 10; //图片形状导致
                            textStr:model.name//"设备名称===="
                            toolTips:model.name
                        }
                    }


                }

                Rectangle{
                    id:detailRect;
                    width:259
                    height: 201
                    anchors.left:imageRect.left;
                    anchors.leftMargin: 82;
                    anchors.top: imageRect.top;
                    anchors.topMargin: 30
                    visible:true
                    color:"transparent"
                    //z:5

                    Timer{
                        id:detailTimer;
                        interval: 10000;
                        repeat: false;
                        running: false;
                        triggeredOnStart: false;
                        onTriggered: {
                            if(model.selected){
                                detailTimer.restart();
                            }else{
                                model.isDetailVisible = false;
                            }

                        }
                    }
                    Loader {
                        id: detailLoader
                        property var alarm: model.alarmInfo
                        property var layerInfo:model.layerData
                        property var layerUser:model.layerUserData
                       // property var bDetailShow:model.isDetailVisible
                        property bool startActive: false
                        anchors.fill:parent;
                        source: !!model.relatedId ? ArConfig.devDetailSource.path : ""
                        focus:true
                        active: startActive
                        visible: opacity != 0
                        opacity: model.isDetailVisible ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation{duration: 1000}
                        }
                        onVisibleChanged: {
                            if(visible && !startActive)
                            {
                                startActive = true;
                            }
                        }

                        onAlarmChanged: {
                            if(status == Loader.Ready)
                            {
                                model.isDetailVisible = true;
                                item.realAlarmInfo = alarm;
                                detailTimer.stop();
                                detailTimer.start();
                                //console.log("onAlarmChanged2", JSON.stringifyitem.alarmInfo)
                            }
                        }
//                        onBDetailShowChanged: {
//                            if(bDetailShow){
//                                if(model.id !== selectedId){
//                                    detailTimer.stop();
//                                    detailTimer.start();
//                                }
//                            }
//                        }
                        onLayerInfoChanged: {
                            console.log("onLayerInfoChanged=====",JSON.stringify(layerInfo));
                            if(status == Loader.Ready)
                            {
                                item.layerData =layerInfo;
                            }

                        }
                        onLayerUserChanged: {
                            console.log("onLayerInfoChanged=====",JSON.stringify(layerUser));
                            if(status == Loader.Ready)
                            {
                                item.layerUserData =layerUser;
                            }
                        }

                        onLoaded: {
                            //  console.log("load....",JSON.stringify(model.devInfo));
                            detailLoader.item.devInfo = model.devInfo;
                            detailLoader.item.layerData = model.layerData;
                            detailLoader.item.layerUserData = model.layerUserData;
                            detailLoader.item.realAlarmInfo = model.alarmInfo;
                        }
                    }
                    Connections{
                        target: detailLoader.item
                        onCloseDetail:{
                            //  console.log("关闭详情页面");
                            model.isDetailVisible=false;
                            //                            image.source=ArConfig.armapList.arDevPointList[0].icon_normal;//model.attribute.url;

                        }
                        onChangeRelatedScence:{
                            //  console.log("切换到关联场景");
                            changeRelatedScence(devId);
                        }
                        onMouseAreaClicked:{
                            //console.log("onMouseAreaClicked=====");
                            model.zIndex = maxZ++;
                        }

                    }
                }
            }
        }

        //线和面类型
        Repeater{
            model: shapeModel
            Rectangle{
                id: allShapesRect
                x: model.geometry.points[0][0]
                y: model.geometry.points[0][1]
                width: 132 * scaleWidthFactor;//model.attribute.width
                height: 21 * scaleWidthFactor;//model.attribute.height
                color:"transparent";
                visible: model.bVisible
                z:model.zIndex

                Timer{
                    id: shapeBgTimer;//去高亮背景
                    interval: 500;
                    repeat: false;
                    running: false;
                    triggeredOnStart: false;
                    onTriggered: {
                        for(var i = 0; i < shapeModel.count; i++)
                        {
                            shapeModel.set(i,{"shapeSelected": false});
                        }
                        requestPaint();
                    }
                }

                Rectangle{
                    id: shapeRect
                    property string id: model.id
                    anchors.fill: parent
//                    x: model.geometry.points[0][0]
//                    y: model.geometry.points[0][1]
                    width: 132 * scaleWidthFactor;
                    height: 21 * scaleWidthFactor;
                    color:"transparent"
                    //rotation: model.attribute["rotate"] ? model.attribute["rotate"] : 0
                    transform: Rotation { origin.x: 0; origin.y: 0; angle: model.attribute["rotate"] ? model.attribute["rotate"] : 0}

                    //精灵动画
                    AnimatedSprite {
                        id: animateImg1
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.topMargin: -width / 2
                        anchors.leftMargin: -height / 2
                        source: model.selected ? model.imgDown : model.imgNormal
                        width: 30
                        height: 30
                        frameWidth: 30
                        frameHeight: 30
                        frameDuration: 200
                        frameCount: 9
                        frameX: 0
                        frameY: 0
                        loops: Animation.Infinite
                        running: true
                        rotation: model.attribute["rotate"] ? -(model.attribute["rotate"]) : 0
                        onVisibleChanged: {
                            if(visible)
                            {
                                animateImg1.restart();
                            }
                        }

                        //z: 2
                        MouseArea{
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            hoverEnabled: true
                            cursorShape: Qt.ArrowCursor;
                            propagateComposedEvents: true; //鼠标透传
                            onClicked: {
                                console.log("onClicked============");
                                model.zIndex = maxZ++;
                                selectedId = model.id;
                                selectedShapeIdx = -1;

                                if(mouse.button == Qt.LeftButton)
                                {
                                    //不选中任何设备
                                    selectImageItem(model.id);
                                    //                                selectedModelItem(shapeModel,selectedId);

                                    for(var i = 0; i < shapeModel.count; i++)
                                    {
                                        if(shapeModel.get(i).id == selectedId)
                                        {
                                            shapeModel.set(i,{"shapeSelected": true});
                                        }
                                        else
                                        {
                                            shapeModel.set(i,{"shapeSelected": false});
                                        }
                                    }
                                    requestPaint();
                                    shapeBgTimer.stop();
                                    shapeBgTimer.start();
                                }
                                else
                                {
                                    //右键菜单-删除/详情/弹出框
                                    editMenuRec.visible = true;
                                    editMenuRec.parent= allShapesRect;
                                    editMenuRec.x = 10// shapeRect.x + mouseX;//+10;
                                    editMenuRec.y = 10//shapeRect.y + mouseY;//+10;
                                }
                            }

                            onDoubleClicked: {
                                console.log("shapeRect  double clicked============");
                                selectedId = model.id;
                                selectedShapeIdx = -1;

                                if(mouse.button == Qt.LeftButton)
                                {
                                    clickItem(model, shapeRect.x + mouseX, shapeRect.y + mouseY);
                                    //不选中任何设备
                                    selectImageItem(model.id);
                                    //selectedModelItem(shapeModel,selectedId);
                                }
                                else
                                {

                                }
                            }
                        }
                    }

                    Rectangle{
                        id: nameRect1
                        anchors.left: animateImg1.left
                        anchors.leftMargin: 26 * scaleWidthFactor
                        anchors.verticalCenter: animateImg1.verticalCenter
                        //anchors.bottom: parent.bottom
                        //anchors.bottomMargin: 4
                        width: titleName1.txtimplicitWidth < 200 * scaleWidthFactor ? (titleName1.txtimplicitWidth < 132 * scaleWidthFactor ? 132 * scaleWidthFactor : titleName1.txtimplicitWidth) : 200 * scaleWidthFactor;//132 * scaleWidthFactor;
                        height: 21 * scaleHeightFactor;
                        color: "transparent"
                        //z: line1.z + 1

                        Image{
                            anchors.fill: parent
                            source: model.selected ? ArConfig.animateImg.animateImgs[0].imageDown
                                                   : ArConfig.animateImg.animateImgs[0].image
                        }

                        TextWithTips{
                            id: titleName1;
                            anchors.left: parent.left
                            anchors.leftMargin: model.attribute["rotate"] >= 90 && model.attribute["rotate"] <= 270 ? 0 : leftMarg
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.rightMargin: model.attribute["rotate"] >= 90 && model.attribute["rotate"] <= 270 ? (titleName1.txtimplicitWidth < nameRect1.width ? (nameRect1.width - titleName1.txtimplicitWidth - 8) : 8 ): 0
                            myTextColor: dataColor;
                            //anchors.rightMargin: 38 * scaleWidthFactor
                            //                            width:130;
                            height: parent.height; //图片形状导致
                            textStr: model.name//"设备名称===="
                            toolTips: model.name
                            z:model.zIndex + 1
                            rotation: model.attribute["rotate"] >= 90 && model.attribute["rotate"] <= 270 ? 180 : 0
                        }

                        MouseArea{
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            hoverEnabled: true
                            cursorShape: Qt.ArrowCursor;
                            propagateComposedEvents: true; //鼠标透传
                            onClicked: {
                                console.log("isDrawing============",isDrawing);
                                model.zIndex = maxZ++;
                                selectedId = model.id;
                                selectedShapeIdx = -1;

                                if(mouse.button == Qt.LeftButton)
                                {
                                    //不选中任何设备
                                    selectImageItem(model.id);
                                    //                                selectedModelItem(shapeModel,selectedId);

                                    for(var i = 0; i < shapeModel.count; i++)
                                    {
                                        if(shapeModel.get(i).id == selectedId)
                                        {
                                            shapeModel.set(i,{"shapeSelected": true});
                                        }
                                        else
                                        {
                                            shapeModel.set(i,{"shapeSelected": false});
                                        }
                                    }
                                    requestPaint();
                                    shapeBgTimer.stop();
                                    shapeBgTimer.start();
                                }
                                else
                                {
                                    //右键菜单-删除/详情/弹出框
                                    editMenuRec.visible = true;
                                    editMenuRec.parent =allShapesRect;
                                    editMenuRec.x =  10;//shapeRect.x + mouseX;//+10;
                                    editMenuRec.y = 10;//shapeRect.y + mouseY;//+10;
                                }
                            }

                            onDoubleClicked: {
                                console.log("onDoubleClicked============");
                                selectedId = model.id;
                                selectedShapeIdx = -1;

                                if(mouse.button == Qt.LeftButton)
                                {
                                    clickItem(model, shapeRect.x + mouseX, shapeRect.y + mouseY);
                                    //不选中任何设备
                                    selectImageItem(model.id);
                                    //selectedModelItem(shapeModel,selectedId);
                                    //arCanvas.drawing();
                                }
                                else
                                {

                                }
                            }
                        }
                    }
                }
            }
        }

        //文本类型
        Repeater{
            model: textModel
            Rectangle{
                id :textRect
                x: model.geometry.points[0][0]
                y: model.geometry.points[0][1]
                z:model.zIndex
                Rectangle{
                    id: text
                    anchors.fill:parent
                    property string id: model.id
                    color:"transparent";
                    visible: model.bVisible
                   // z:model.zIndex
                    //加入model时，数组被转成了model类型
//                    x: model.geometry.points[0][0]
//                    y: model.geometry.points[0][1]
                    rotation: model.attribute["rotate"]

                    //精灵动画
                    AnimatedSprite {
                        id: animateImg2
                        anchors.top: parent.top
                        anchors.topMargin: -height / 2
                        anchors.left: parent.left
                        anchors.leftMargin: -width / 2
                        source: model.selected ? model.imgDown : model.imgNormal
                        width: 30
                        height: 30
                        frameWidth: 30
                        frameHeight: 30
                        frameDuration: 200
                        frameCount: 9
                        frameX: 0
                        frameY: 0
                        loops: Animation.Infinite
                        running: true
                        rotation: model.attribute["rotate"] ? -(model.attribute["rotate"]) : 0
                        onVisibleChanged: {
                            if(visible)
                            {
                                animateImg2.restart();
                            }
                        }

                        //z: 2
                        MouseArea{
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            hoverEnabled: true
                            cursorShape: Qt.ArrowCursor;
                            propagateComposedEvents: true; //鼠标透传
                            onClicked: {
                                model.zIndex = maxZ++;
                                selectedId = model.id;
                                selectedShapeIdx = -1;
                                // clickItem(model.id, x, y);
                                if(mouse.button == Qt.LeftButton)
                                {
                                    //clickItem(model, text.x + text.width, text.y);
                                    //不选中任何设备
                                    selectImageItem(model.id);
                                    //                                selectedModelItem(textModel,model.id);
                                }
                                else //if(mouse.button == Qt.RightButton)
                                {
                                    //右键菜单-删除/详情/弹出框
                                    console.log("text right click")
                                    editMenuRec.visible = true;
                                    editMenuRec.parent= textRect;
                                    editMenuRec.x =  10;
                                    editMenuRec.y =  10;
                                }
                            }
                            onDoubleClicked: {
                                console.log("onDoubleClicked text============");
                                selectedId = model.id;
                                selectedShapeIdx = -1;

                                if(mouse.button == Qt.LeftButton)
                                {
                                    clickItem(model, text.x + mouseX, text.y + mouseY);
                                    //不选中任何设备
                                    selectImageItem(model.id);
                                    //selectedModelItem(shapeModel,selectedId);
                                }
                                else
                                {

                                }
                            }
                        }
                    }

                    Rectangle{
                        id: nameRect2
                        anchors.left: animateImg2.left
                        anchors.leftMargin: 26 * scaleWidthFactor
                        anchors.verticalCenter: animateImg2.verticalCenter
                        width: titleName2.txtimplicitWidth < 300 * scaleWidthFactor ? (titleName2.txtimplicitWidth < 132 * scaleWidthFactor ? 132 * scaleWidthFactor : titleName2.txtimplicitWidth) : 300 * scaleWidthFactor;
                        height: titleName2.txtimplicitHeight < 21 * scaleHeightFactor ? 21 * scaleHeightFactor : titleName2.txtimplicitHeight //model.attribute.fontSize <= 14 ? 21 * scaleHeightFactor : model.attribute.fontSize + 7//30 * scaleHeightFactor;//随着字体大小 设置高度
                        color: "transparent"
                        //rotation: model.attribute["rotate"]

                        //z: line1.z + 1

                        Image{
                            anchors.fill: parent
                            source: model.selected ? ArConfig.animateImg.animateImgs[0].imageDown
                                                   : ArConfig.animateImg.animateImgs[0].image
                        }

                        TextWithTips{
                            id: titleName2;
                            anchors.left: parent.left
                            anchors.leftMargin: model.attribute["rotate"] >= 90 && model.attribute["rotate"] <= 270 ? 0 : leftMarg
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.rightMargin: model.attribute["rotate"] >= 90 && model.attribute["rotate"] <= 270 ? (titleName2.txtimplicitWidth < nameRect2.width ? (nameRect2.width - titleName2.txtimplicitWidth - 8) : 8 ): 0
                            // width:130;
                            height: parent.height; //图片形状导致
                            textStr: model.name//"设备名称===="
                            toolTips: model.name
                            myTextColor: model.attribute["color"]
                            fontSize: model.attribute["fontSize"]
                            fontFamily: model.attribute["fontFamily"]
                            //rotation: model.attribute["rotate"]
                            fontItalic :model.attribute["italicSelected"]
                            fontBold:model.attribute["boldSelected"]
                            fontUnderline: model.attribute["underlineSelected"]
                            rotation: model.attribute["rotate"] >= 90 && model.attribute["rotate"] <= 270 ? 180 : 0
                            //                transform: Rotation {
                            //                    origin.x: model.x;
                            //                    origin.y: model.y
                            //                    angle: model.rotate
                            //                }
                        }

                        MouseArea{
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            //                        hoverEnabled: true
                            cursorShape: Qt.ArrowCursor;
                            propagateComposedEvents: true; //鼠标透传
                            onClicked: {
                                model.zIndex = maxZ++;
                                selectedId = model.id;
                                selectedShapeIdx = -1;
                                //clickItem(model, x, y);
                                if(mouse.button == Qt.LeftButton)
                                {
                                    //clickItem(model, text.x + text.width, text.y);
                                    //不选中任何设备
                                    selectImageItem(model.id);
                                    //selectedModelItem(textModel,model.id);
                                }
                                else //if(mouse.button == Qt.RightButton)
                                {
                                    //右键菜单-删除/详情/弹出框
                                    console.log("text right click")
                                    editMenuRec.visible = true;
                                    editMenuRec.parent = textRect;
                                    editMenuRec.x =  10;
                                    editMenuRec.y =  10;
                                }
                            }
                            onDoubleClicked: {
                                console.log("onDoubleClicked text============");
                                selectedId = model.id;
                                selectedShapeIdx = -1;

                                if(mouse.button == Qt.LeftButton)
                                {
                                    clickItem(model, text.x + mouseX, text.y + mouseY);
                                    //不选中任何设备
                                    selectImageItem(model.id);
                                    //selectedModelItem(shapeModel,selectedId);
                                }
                                else
                                {

                                }
                            }
                        }
                    }
                }

            }

        }
    }

    //超视距平台
    Rectangle{
        id:mobileRect
        anchors.bottom: parent.bottom;
        anchors.horizontalCenter: parent.horizontalCenter;
        color: "transparent"
        width:1185
        height: 280
        visible:getVisibleCnt() > 0? true:false;

        Rectangle{
            id:backPlate
            anchors.bottom: parent.bottom;
            anchors.left: parent.left;
            width:1185
            height:37
            color:"transparent"
            z:1;
           Image{
                id:bgImage;
                anchors.fill:parent;
                source:ArConfig.armapList.mobileDev.showcaseBg
            }
            MouseArea{
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                hoverEnabled: true
                cursorShape: Qt.ArrowCursor;
                propagateComposedEvents: true; //鼠标透传
                onClicked: {
                    bMobileVideo = !bMobileVideo;
                 //   console.log("mobileModel.count=======",mobileModel.count,bMobileVideo);
                    for( var i = 0; i < mobileModel.count ; i++){
                         mobileModel.setProperty(i,"bVideoVisible",bMobileVideo);
                    }

                }
            }
        }
//        Image{
//            anchors.centerIn: backPlate;
//            anchors.verticalCenterOffset:8
//            source: ArConfig.armapList.mobileDev.icon_platform

//        }

        ImageButton{
            id:prevBtn
            anchors.left:parent.left;
            anchors.leftMargin: 35
            anchors.verticalCenter: backPlate.verticalCenter;
            anchors.verticalCenterOffset: 5 ;
            bIsNeedBgPic: false
            bSelectedEnabled: true
            btnEnabled: false//mobileView.currentIndex=== 0 ? false : true
            imgnormal:ArConfig.armapList.mobileDev.left_arrow
            imghover:ArConfig.armapList.mobileDev.left_arrow_hov
            imgdown:ArConfig.armapList.mobileDev.left_arrow
            imgdisable:ArConfig.armapList.mobileDev.left_arrow_dis

            visible: getVisibleCnt() > 5 ? true:false;//mobileModel.count > 5 ? true : false//mobileVisibleModel.count >5 ? true :false//mobileModel.count > 5 ? true : false////
            z:backPlate.z+1
            onClicked: {
                  mobileView.currentIndex--;
                  controlBtn();
            }
        }
        ImageButton{
            id:nextBtn
            anchors.top: prevBtn.top;
            anchors.right:parent.right;
            anchors.rightMargin: 35;
            bIsNeedBgPic: false
            bSelectedEnabled: true
            btnEnabled:true //(mobileView.currentIndex + 5)> mobileModel.count ? true : false
            imgnormal:ArConfig.armapList.mobileDev.right_arrow
            imghover:ArConfig.armapList.mobileDev.right_arrow_hov
            imgdown:ArConfig.armapList.mobileDev.right_arrow
            imgdisable:ArConfig.armapList.mobileDev.right_arrow_dis;

            z:backPlate.z+1
            visible:getVisibleCnt() > 5 ? true:false;//mobileModel.count > 5 ? true : false//mobileVisibleModel.count>5? true :false//mobileModel.count > 5 ? true : false//getVisibleCnt() > 5 ? true:false;//
            onClicked: {
                mobileView.currentIndex++ ;
                controlBtn();
            }
        }

        Component{
            id:mobileDelegate
            Rectangle{
                color:"transparent"
                anchors.bottom: parent.bottom
                width:!!model.bVisible&&model.bVisible ? 210 :0
                height:alarmRect.visible ? alarmRect.height+moRect.height: moRect.height;
                visible: model.bVisible
//                border.color: "yellow"
//                border.width: 1
                //告警
                Rectangle{
                    id:alarmRect
                    visible: opacity != 0
                    opacity:!!model.isDetailVisible ? (model.isDetailVisible ? 1 : 0) : 0//
                    anchors.bottom: moRect.top
                    anchors.bottomMargin: 2
                    //anchors.top:parent.top
//                    anchors.left:moRect.left
//                    anchors.leftMargin: 1
                    width:184
                    height:129
                    anchors.horizontalCenter:  moRect.horizontalCenter
                    anchors.horizontalCenterOffset: -5
                    color: "transparent"

                    Behavior on opacity {
                        NumberAnimation{duration: 1000}
                    }
                    Timer{
                        id:alarmShowTimer;
                        interval: 10000;
                        repeat: false;
                        running: false;
                        triggeredOnStart: false;
                        onTriggered: {
                            //console.log("alarmShowTimer onTriggered===");
                            model.isDetailVisible = false;
                        }
                    }

                    Loader {
                        id:alarmLoader;
                        property var alarm: model.alarmInfo
                        property var bAlarmShow: model.isDetailVisible
                        anchors.fill:parent;
                        source: ArConfig.mobileAlarmSource.path
                        focus:true
                        active:true
                        onAlarmChanged: {

                            if(status == Loader.Ready)
                            {
                                model.isDetailVisible = true;
                                item.alarmInfo = alarm;
                            }
                        }
                        onLoaded: {
                            if(status == Loader.Ready){
                                 alarmLoader.item.alarmInfo = model.alarmInfo;
                            }
                        }
                        onBAlarmShowChanged: {
                            if(status == Loader.Ready){
                      //          console.log("onBAlarmShowChanged==========",bAlarmShow);
                                if(bAlarmShow){
                                    alarmShowTimer.stop();
                                    alarmShowTimer.start();
                                }
                            }
                        }
                    }
                    Connections{
                        target: alarmLoader.item;
                        onCloseAlarm:{
                            model.isDetailVisible = false;
                        }
                    }

                }

                //移动设备
                Rectangle{
                    id:moRect
                    width:199
                    height: model.bVideoVisible ? 143 :38;
                    anchors.horizontalCenter: parent.horizontalCenter
                    //anchors.top:alarmRect.visible ? alarmRect.bottom : parent.top;
                    anchors.bottom:parent.bottom
                    color:"transparent"
                    visible: !!model.bVisible ? model.bVisible : true
                    MouseArea{
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        hoverEnabled: true
                        cursorShape: Qt.ArrowCursor;
                        propagateComposedEvents: true; //鼠标透传
                        // z:1000
                        onClicked: {
                            selectedId = model.id;
                         //   console.log("selectedId==========",selectedId);
                            selectedShapeIdx = -1;
                            if(mouse.button == Qt.LeftButton)
                            {
                                selectImageItem(model.id);
                            }
                            else //if(mouse.button == Qt.RightButton)
                            {
                                //右键菜单-删除/详情/弹出框

                                editMenuRec.visible = true;
                                editMenuRec.parent = moRect;
                                editMenuRec.x = mouseX+20;
                                editMenuRec.y = mouseY-30;
//                                editMenuRec.x = arCanvas.width/2-backPlate.width/2 + 45;
//                                editMenuRec.y =  arCanvas.height-130;
                            }
                        }

                        onDoubleClicked: {
                            console.log("moRect onDoubleClicked============",model.id,model.attribute.type);
                            selectedId = model.id;
                            selectedShapeIdx = -1;

                            if(mouse.button == Qt.LeftButton)
                            {
//                                //不选中任何设备
                                selectImageItem(model.id);
                                clickItem(model,null,null);

                            }

                        }

                    }

                    Loader {
                        id:mobileLoader;
                        anchors.fill:parent;
                        property bool bSel: model.selected
                        property bool bVideo: model.bVideoVisible
                        property string mName :model.name
                        source: ArConfig.mobileDevSource.path
                        focus:true
                        active:true

                        onLoaded: {
                            mobileLoader.item.devInfo = model.devInfo;
                            mobileLoader.item.titleIcon = model.attribute.typeIcon;
                            mobileLoader.item.titleName = model.name;
                            mobileLoader.item.id = model.id;
                            mobileLoader.item.lockState = model.bLocked ===0 ? false : true;
                            mobileLoader.item.bVideoshow = model.bVideoVisible;
                        }
                        onBSelChanged: {
                            if(status == Loader.Ready){
                                mobileLoader.item.bSelected = bSel;
                            }

                        }
                        onBVideoChanged: {
                            if(status == Loader.Ready){
                            //    console.log("onBVideoChanged====================");
                                mobileLoader.item.bVideoshow = bVideo;
                            }
                        }
                        onMNameChanged: {
                            if(status == Loader.Ready){
                                console.log("titleName=====",mName);
                                mobileLoader.item.titleName = mName;
                            }
                        }
                    }
                    Connections{
                        target: mobileLoader.item;
                        onDevLockClick:{//id,state
                            //console.log("onDevLockClick======",id,state);
                            mobileLockStateChange(id,state);
                        }
                        onChangeRelatedScence:{
                            console.log("切换到关联场景");
                            changeRelatedScence(devId);
                        }
                    }
                }
            }
        }



        ListView {
            id: mobileView;
//            anchors.left:prevBtn.right;
//            anchors.leftMargin: 10
//            anchors.right:nextBtn.left;
            anchors.bottom: parent.bottom;
            anchors.bottomMargin: 7
            anchors.horizontalCenter: parent.horizontalCenter
            model:mobileModel;// mobileVisibleModel//mobileModel;
            width: Math.min(5*210,getVisibleCnt() * 210)//mobileModel.count *210)//mobileVisibleModel.count*210)//mobileModel.count *210)//getVisibleCnt() * 210)//)
            height:mobileDelegate.height
            orientation: ListView.Horizontal
            snapMode: ListView.SnapOneItem
            spacing:1
            highlightRangeMode:ListView.StrictlyEnforceRange //currentIndex跟随变化
            delegate: mobileDelegate;
            currentIndex:0
            focus: true;
            z:backPlate.z+2
           
        }
    }


    Rectangle {
        id: editMenuRec;
        height: 34;
        color: "transparent";
        visible: false;
        Column{
            id: editRow
            anchors.fill: parent

            CommonButtonBlue {
                id: editBtn;
//                anchors.top:parent.top;
                width: 80;
                textCon:ArConfig.EmapLang.interestEdit;//编辑兴趣点
                fontSize: fontSizeSmall;
                fontFamily: fontFamily;
                imgnormalY: EvisConfig.CtrlList.RLoginBtn.normal
                imghoverY: EvisConfig.CtrlList.RLoginBtn.hover;
                imgdownY: EvisConfig.CtrlList.RLoginBtn.down;
                imgnormal: EvisConfig.CtrlList.RLoginBtn.normal
                imghover: EvisConfig.CtrlList.RLoginBtn.hover;
                imgdown: EvisConfig.CtrlList.RLoginBtn.down;
                onClicked: {
                   // arCanvas.getSelectedDetail(selectedId);

                    editMenuRec.visible = false;
                    rightButtonOpr("modify",selectedId);
                }

            }
            CommonButtonBlue {
                id: deleteBtn;
                width: 80;
                textCon: ArConfig.EmapLang.deleteInterest;
                fontSize: fontSizeSmall;
                fontFamily: fontFamily;
                imgnormalY: EvisConfig.CtrlList.RLoginBtn.normal
                imghoverY: EvisConfig.CtrlList.RLoginBtn.hover;
                imgdownY: EvisConfig.CtrlList.RLoginBtn.down;
                imgnormal: EvisConfig.CtrlList.RLoginBtn.normal
                imghover: EvisConfig.CtrlList.RLoginBtn.hover;
                imgdown: EvisConfig.CtrlList.RLoginBtn.down;
                onClicked: {
                    //console.log("selectedId", selectedId);
                     rightButtonOpr("delete",selectedId);
//                    arCanvas.removeShape(selectedId);
                    editMenuRec.visible = false;
                    selectedId = "";
                    selectedShapeIdx = -1;
                }
            }
        }
    }
}
