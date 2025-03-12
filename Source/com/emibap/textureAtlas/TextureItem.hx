package com.emibap.textureAtlas;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.geom.Rectangle;

class TextureItem extends Sprite {

    private var _graphic:BitmapData;
    private var _textureName:String = "";
    private var _frameName:String = "";
    private var _frameX:Int = 0;
    private var _frameY:Int = 0;
    private var _frameWidth:Int = 0;
    private var _frameHeight:Int = 0;

    public function new(graphic:BitmapData, textureName:String, frameName:String, frameX:Int = 0, frameY:Int = 0, frameWidth:Int = 0, frameHeight:Int = 0) {
        super();

        _graphic = graphic;
        _textureName = textureName;
        _frameName = frameName;
        _frameWidth = frameWidth;
        _frameHeight = frameHeight;
        _frameX = frameX;
        _frameY = frameY;

        var bm:Bitmap = new Bitmap(graphic);
        bm.smoothing = false; // Instead of "auto"
        addChild(bm);
    }

    public var textureName(get, never):String;
    function get_textureName():String return _textureName;

    public var frameName(get, never):String;
    function get_frameName():String return _frameName;

    public var graphic(get, never):BitmapData;
    function get_graphic():BitmapData return _graphic;

    public var frameX(get, never):Int;
    function get_frameX():Int return _frameX;

    public var frameY(get, never):Int;
    function get_frameY():Int return _frameY;

    public var frameWidth(get, never):Int;
    function get_frameWidth():Int return _frameWidth;

    public var frameHeight(get, never):Int;
    function get_frameHeight():Int return _frameHeight;
}
