package com.emibap.textureAtlas;

import haxe.xml.Access;
import haxe.ds.Vector;

import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.text.AntiAliasType;
import openfl.text.Font;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.filters.BitmapFilter;
import openfl.Lib.getQualifiedClassName;

import starling.text.BitmapFont;
import starling.textures.Texture;
import starling.textures.TextureAtlas;
import starling.text.TextField;

import com.emibap.textureAtlas.TextureItem;

/**
	* DynamicAtlas.as
	* https://github.com/emibap/Dynamic-Texture-Atlas-Generator
	*@author Emibap (Emiliano Angelini) - http://www.emibap.com
			 * Contribution by Thomas Haselwanter - https://github.com/thomashaselwanter
	* Most of this comes thanks to the inspiration (and code) of Thibault Imbert (http://www.bytearray.org) and Nicolas Gans (http://www.flashxpress.net/)
	* 
	* Dynamic Texture Atlas and Bitmap Font Generator (Starling framework Extension)
	* ========
	*
	* This tool will convert any MovieClip containing Other MovieClips, Sprites or Graphics into a starling Texture Atlas, all in runtime.
	* It can also register bitmap Fonts from system or embedded regular fonts.
	* By using it, you won't have to statically create your spritesheets or fonts. For instance, you can just take a regular MovieClip containing all the display objects you wish to put into your Altas, and convert everything from vectors to bitmap textures.
	* Or you can select which font (specifying characters) you'd like to register as a Bitmap Font, using a string or passing a Regular TextField as a parameter.
	* This extension could save you a lot of time specially if you'll be coding mobile apps with the [starling framework](http://www.starling-framework.org/).
	*
	* # version 1.0 #
	* - Added the checkBounds parameter to scan the clip prior the rasterization in order to get the bounds of the entire MovieClip (prevent scaling in some cases). Thank you Aymeric Lamboley.
	* - Added the fontCustomID parameter to the Bitmap font creation. Thank you Regan.
	*
	* ### Features ###
	*
	* * Dynamic creation of a Texture Atlas from a MovieClip (openfl.display.MovieClip) container that could act as a sprite sheet, or from a Vector of Classes
	* * Filters made to the objects are captured
	* * Color transforms (tint, alpha) are optionally captured
	* * Scales the objects (and also the filters) to a specified value
	* * Automatically detects the objects bounds so you don't necessarily have to set the registration points to TOP LEFT
	* * Registers Bitmap Fonts based on system or embedded fonts from strings or from good old Flash TextFields
	* 
	* ### TODO List ###
	*
	* * Further code optimization
	* * A better implementation of the Bitmap Font creation process
	* * Documentation (?)
	*
	* ### Whish List ###
	* * Optional division of the process into small intervals (for smooth performance of the app)
	* 
	* ### Usage ###
	* 
	* 	You can use the following static methods (examples at the gitHub Repo):
	*	
	* 	[Texture Atlas creation]
	* 	- DynamicAtlas.fromMovieClipContainer(swf:openfl.display.MovieClip, scaleFactor:Float = 1, margin:UInt=0, preserveColor:Bool = true):starling.textures.TextureAtlas
	* 	- DynamicAtlas.fromClassVector(assets:Array<Class>, scaleFactor:Float = 1, margin:UInt=0, preserveColor:Bool = true):starling.textures.TextureAtlas
	*
	* [Bitmap Font registration]
	* - DynamicAtlas.bitmapFontFromString(chars:String, fontFamily:String, fontSize:Float = 12, bold:Bool = false, italic:Bool = false, charMarginX:Int=0):Void
	* - DynamicAtlas.bitmapFontFromTextField(tf:openfl.text.TextField, charMarginX:Int=0):Void
	*
	* 	Enclose inside a try/catch for error handling:
	* 		try {
	* 				var atlas:TextureAtlas = DynamicAtlas.fromMovieClipContainer(mc);
	* 			} catch (e:Error) {
	* 				trace("There was an error in the creation of the texture Atlas. Please check if the dimensions of your clip exceeded the maximun allowed texture size. -", e.message);
	* 			}
	*
	*  History:
	*  -------
	* # version 0.9.5 #
	* - Added the fromClassVector static function. Thank you Thomas Haselwanter
	* 
	* # version 0.9 #
	* - Added Bitmap Font creation support
	* - Scaling also applies to filters.
	* - Added Margin and PreserveColor Properties
	* 
	* # version 0.8 #
	* - Added the scaleFactor constructor parameter. Now you can define a custom scale to the final result.
	* - Scaling also applies to filters.
	* - Added Margin and PreserveColor Properties
	* 
	* # version 0.7 #
	* First Public version
**/
class DynamicAtlas {
	static private inline var DEFAULT_CANVAS_WIDTH:Float = 2048;
	static private var canvasWidth:Float = DEFAULT_CANVAS_WIDTH;

	static private var _items:Array<Dynamic>;
	static private var _canvas:Sprite;

	static private var _currentLab:String;

	static private var _x:Float;
	static private var _y:Float;

	static private var _bData:BitmapData;
	static private var _mat:Matrix;
	static private var _margin:Float;
	static private var _preserveColor:Bool;

	static private var pivots:Map<String, Point> = [];

	// Will not be used - Only using one static method
	public function new() {}

	// Private methods

	static private function appendIntToString(num:Int, numOfPlaces:Int):String {
		var numString:String = Std.string(num);
		var outString:String = "";
		for (i in 0...(numOfPlaces - numString.length)) {
			outString += "0";
		}
		return outString + numString;
	}

	static private function layoutChildren():Void {
		var xPos:Float = 0;
		var yPos:Float = 0;
		var maxY:Float = 0;
		var len:Int = _items.length;

		var itm:TextureItem;
		for (i in 0...len) {
			itm = _items[i];

			if ((xPos + itm.width) > canvasWidth) {
				xPos = 0;
				yPos += maxY;
				maxY = 0;
			}
			if (itm.height + 1 > maxY) {
				maxY = itm.height + 1;
			}
			itm.x = xPos;
			itm.y = yPos;
			xPos += itm.width + 1;
		}
	}

	/**
		* isEmbedded
		* 
		*@param	fontFamily:Bool - The name of the Font
		*@return Bool - True if the font is an embedded one
	 */
	static private function isEmbedded(fontFamily:String):Bool {
		var embeddedFonts:Array<Font> = Font.enumerateFonts();

		var i:Int = Std.int(embeddedFonts.length - 1);
		while (i > -1 && embeddedFonts[i].fontName != fontFamily) {
			i--;
		}

		return (i > -1);
	}

	static private function getRealBounds(clip:DisplayObject):Rectangle {
		var bounds:Rectangle = clip.getBounds(clip.parent);
		bounds.x = Math.floor(bounds.x);
		bounds.y = Math.floor(bounds.y);
		bounds.height = Math.ceil(bounds.height);
		bounds.width = Math.ceil(bounds.width);

		var realBounds:Rectangle = new Rectangle(0, 0, bounds.width + _margin * 2, bounds.height + _margin * 2);
		var tmpBData:BitmapData;

		// Checking filters in case we need to expand the outer bounds
		if (clip.filters.length > 0) {
			// filters
			var j:Int = 0;
			// var clipFilters:Array<Dynamic> = clipChild.filters.concat();
			var clipFilters:Array<Dynamic> = clip.filters;
			var clipFiltersLength:Int = clipFilters.length;
			var filterRect:Rectangle;

			tmpBData = new BitmapData(Std.int(realBounds.width), Std.int(realBounds.height), false);
			filterRect = tmpBData.generateFilterRect(tmpBData.rect, clipFilters[j]);
			realBounds = realBounds.union(filterRect);
			tmpBData.dispose();

			while (++j < clipFiltersLength) {
				tmpBData = new BitmapData(Std.int(filterRect.width), Std.int(filterRect.height), true, 0);
				filterRect = tmpBData.generateFilterRect(tmpBData.rect, clipFilters[j]);
				realBounds = realBounds.union(filterRect);
				tmpBData.dispose();
			}
		}

		realBounds.offset(bounds.x, bounds.y);
		realBounds.width = Math.max(realBounds.width, 1);
		realBounds.height = Math.max(realBounds.height, 1);

		tmpBData = null;
		return realBounds;
	}

	/**
		* drawItem - This will actually rasterize the display object passed as a parameter
		*@param	clip
		*@param	name
		*@param	baseName
		*@param	clipColorTransform
		*@param	frameBounds
		*@return TextureItem
	 */
	static private function drawItem(clip:DisplayObject, name:String = "", baseName:String = "", clipColorTransform:ColorTransform = null,
			frameBounds:Rectangle = null):TextureItem {
		var realBounds:Rectangle = getRealBounds(clip);

		_bData = new BitmapData(Std.int(realBounds.width), Std.int(realBounds.height), true, 0);
		_mat = clip.transform.matrix;
		_mat.translate(-realBounds.x + _margin, -realBounds.y + _margin);

		_bData.draw(clip, _mat, _preserveColor ? clipColorTransform : null);

		var label:String = "";
		if (Std.isOfType(clip, MovieClip)) {
			if (cast(clip, MovieClip).currentLabel != _currentLab && cast(clip, MovieClip).currentLabel != null) {
				_currentLab = cast(clip, MovieClip).currentLabel;
				label = _currentLab;
			}
		}

		if (frameBounds != null) {
			realBounds.x = frameBounds.x - realBounds.x;
			realBounds.y = frameBounds.y - realBounds.y;
			realBounds.width = frameBounds.width;
			realBounds.height = frameBounds.height;
		}

		var item:TextureItem = new TextureItem(_bData, name, label, Std.int(realBounds.x), Std.int(realBounds.y), Std.int(realBounds.width),
			Std.int(realBounds.height));

		_items.push(item);
		_canvas.addChild(item);

		_bData = null;

		return item;
	}

	// Public methods

	/**
		* This method allow to change the width of the textures atlases
		*@param	width:Float - The new width of the canvas
	 */
	static public function setCanvasWidth(width:Int):Void {
		canvasWidth = width;
	}

	/**
		* This method return the pivot of the Symbol used to create the Atlas
		*@param	name name of the asset
		*@return	the pivot point
	 */
	static public function getPivot(name:String):Point {
		return pivots[name];
	}

	/**
		* This method takes a vector of DisplayObject class and converts it into a Texture Atlas.
		*
		*@param	assets:Array<Dynamic> - The DisplayObject classes you wish to convert into a TextureAtlas. Must contain classes whose instances are of type DisplayObject that will be rasterized and become the subtextures of your Atlas.
		*@param	scaleFactor:Float - The scaling factor to apply to every object. Default value is 1 (no scaling).
		*@param	margin:UInt - The amount of pixels that should be used as the resulting image margin (for each side of the image). Default value is 0 (no margin).
		*@param	preserveColor:Bool - A Flag which indicates if the color transforms should be captured or not. Default value is true (capture color transform).
		*@param 	checkBounds:Bool - A Flag used to scan the clip prior the rasterization in order to get the bounds of the entire MovieClip. By default is false because it adds overhead to the process.
		*@return  TextureAtlas - The dynamically generated Texture Atlas.
	 */
	static public function fromClassVector(assets:Array<Dynamic>, scaleFactor:Float = 1, margin:UInt = 0, preserveColor:Bool = true,
			checkBounds:Bool = false):TextureAtlas {
		var container:MovieClip = new MovieClip();
		for (assetClass in assets) {
			var assetInstance:DisplayObject = Type.createInstance(assetClass, []);
			assetInstance.name = getQualifiedClassName(assetClass);
			container.addChild(assetInstance);
		}
		return fromMovieClipContainer(container, scaleFactor, margin, preserveColor, checkBounds);
	}

	/** Retrieves all textures for a class. Returns <code>null</code> if it is not found.
	 * This method can be used if TextureAtlass doesn't support classes.
	 */
	static public function getTexturesByClass(textureAtlas:TextureAtlas, assetClass:Dynamic):openfl.Vector<Texture> {
		return textureAtlas.getTextures(getQualifiedClassName(assetClass));
	}

	/**
		* This method will take a MovieClip sprite sheet (containing other display objects) and convert it into a Texture Atlas.
		* 
		*@param	swf:MovieClip - The MovieClip sprite sheet you wish to convert into a TextureAtlas. I must contain named instances of every display object that will be rasterized and become the subtextures of your Atlas.
		*@param	scaleFactor:Float - The scaling factor to apply to every object. Default value is 1 (no scaling).
		*@param	margin:UInt - The amount of pixels that should be used as the resulting image margin (for each side of the image). Default value is 0 (no margin).
		*@param	preserveColor:Bool - A Flag which indicates if the color transforms should be captured or not. Default value is true (capture color transform).
		*@param 	checkBounds:Bool - A Flag used to scan the clip prior the rasterization in order to get the bounds of the entire MovieClip. By default is false because it adds overhead to the process.
		*@return  TextureAtlas - The dynamically generated Texture Atlas.
	 */
	static public function fromMovieClipContainer(swf:Sprite, scaleFactor:Float = 1, margin:UInt = 0, preserveColor:Bool = true,
			checkBounds:Bool = false):TextureAtlas {
		var parseFrame:Bool = false;
		var selected:DisplayObject;
		var selectedTotalFrames:Int;
		var selectedColorTransform:ColorTransform;
		var frameBounds:Rectangle = new Rectangle(0, 0, 0, 0);

		var children:UInt = swf.numChildren;

		var canvasData:BitmapData;

		var texture:Texture;
		var xml:Access;
		var subText:Access;
		var atlas:TextureAtlas;

		var itemsLen:Int;
		var itm:TextureItem;

		var m:UInt;

		_margin = margin;
		_preserveColor = preserveColor;

		_items = [];

		if (_canvas == null)
			_canvas = new Sprite();

		if (Std.isOfType(swf, MovieClip))
			cast(swf, MovieClip).gotoAndStop(1);

		static var scales:Vector<Point>;

		if (scaleFactor != 1)
			scales = new Vector<Point>(children);

		for (i in 0...children) {
			selected = swf.getChildAt(i);
			selectedColorTransform = selected.transform.colorTransform;
			_x = selected.x;
			_y = selected.y;

			// Scaling if needed (including filters)
			if (scaleFactor != 1) {
				scales[i] = new Point(selected.scaleX, selected.scaleY);

				selected.scaleX *= scaleFactor;
				selected.scaleY *= scaleFactor;

				if (selected.filters.length > 0) {
					var filters:Array<BitmapFilter> = selected.filters;
					var filtersLen:Int = selected.filters.length;
					var filter:Dynamic;

					for (j in 0...filtersLen) {
						filter = filters[j];

						if (Reflect.hasField(filter, "blurX")) {
							filter.blurX *= scaleFactor;
							filter.blurY *= scaleFactor;
						}
						if (Reflect.hasField(filter, "distance")) {
							filter.distance *= scaleFactor;
						}
					}
					selected.filters = filters;
				}
			}

			// Not all children will be MCs. Some could be sprites
			if (Std.isOfType(selected, MovieClip)) {
				selectedTotalFrames = cast(selected, MovieClip).totalFrames;
				// Gets the frame bounds by performing a frame-by-frame check
				if (checkBounds) {
					cast(selected, MovieClip).gotoAndStop(0);
					frameBounds = getRealBounds(selected);
					m = 1;
					while (++m <= cast selectedTotalFrames) {
						cast(selected, MovieClip).gotoAndStop(m);
						frameBounds = frameBounds.union(getRealBounds(selected));
					}

					pivots[selected.name] = new Point(-frameBounds.x + margin, -frameBounds.y + margin);
				}
			} else
				selectedTotalFrames = 1;
			m = 0;
			// Draw every frame (if MC - else will just be one)
			while (++m <= cast selectedTotalFrames) {
				if (Std.isOfType(selected, MovieClip))
					cast(selected, MovieClip).gotoAndStop(m);
				drawItem(selected, selected.name + "_" + appendIntToString(m - 1, 5), selected.name, selectedColorTransform, frameBounds);
			}
		}

		_currentLab = "";

		layoutChildren();

		canvasData = new BitmapData(Std.int(_canvas.width), Std.int(_canvas.height), true, 0x000000);
		canvasData.draw(_canvas);

		xml = new Access(Xml.parse('<TextureAtlas></TextureAtlas>').firstElement());
		xml.att.imagePath = "atlas.png";

		itemsLen = _items.length;

		for (k in 0...itemsLen) {
			itm = _items[k];

			// xml
			subText = new Access(Xml.parse('<SubTexture />').firstElement());
			subText.att.name = itm.textureName;
			subText.att.x = Std.string(itm.x);
			subText.att.y = Std.string(itm.y);
			subText.att.width = Std.string(itm.width);
			subText.att.height = Std.string(itm.height);
			subText.att.frameX = Std.string(itm.frameX);
			subText.att.frameY = Std.string(itm.frameY);
			subText.att.frameWidth = Std.string(itm.frameWidth);
			subText.att.frameHeight = Std.string(itm.frameHeight);

			if (itm.frameName != "")
				subText.att.frameLabel = Std.string(itm.frameName);
			xml.x.addChild(subText.x);

			itm.graphic.dispose();
		}
		texture = Texture.fromBitmapData(canvasData);
		atlas = new TextureAtlas(texture, xml.x);

		_items.resize(0);
		_canvas.removeChildren();

		_items = null;
		xml = null;
		_canvas = null;
		_currentLab = null;
		// _x = _y = _margin = null;

		if (scaleFactor != 1) {
			var scale:Point;

			for (i in 0...children) {
				scale = scales[i];
				selected = swf.getChildAt(i);
				selected.scaleX = scale.x;
				selected.scaleY = scale.y;
			}
		}

		return atlas;
	}

	/**
		* This method will register a Bitmap Font based on each char that belongs to a String.
		* 
		*@param	chars:String - The collection of chars which will become the Bitmap Font
		*@param	fontFamily:String - The name of the Font that will be converted to a Bitmap Font
		*@param	fontSize:Float - The size in pixels of the font.
		*@param	bold:Bool - A flag indicating if the font will be rasterized as bold.
		*@param	italic:Bool - A flag indicating if the font will be rasterized as italic.
		*@param	charMarginX:Int - The Float of pixels that each character should have as horizontal margin (negative values are allowed). Default value is 0.
		*@param	fontCustomID:String - A custom font family name indicated by the user. Helpful when using differnt effects for the same font. [Optional]
	 */
	static public function bitmapFontFromString(chars:String, fontFamily:String, fontSize:Float = 12, bold:Bool = false, italic:Bool = false,
			charMarginX:Int = 0, fontCustomID:String = ""):Void {
		var format:TextFormat = new TextFormat(fontFamily, Std.int(fontSize), 0xFFFFFF, bold, italic);
		var tf:openfl.text.TextField = new openfl.text.TextField();

		tf.autoSize = TextFieldAutoSize.LEFT;

		// If the font is an embedded one (I couldn't get to work the Array<Dynamic>.indexOf method) :(
		if (isEmbedded(fontFamily)) {
			tf.antiAliasType = AntiAliasType.ADVANCED;
			tf.embedFonts = true;
		}

		tf.defaultTextFormat = format;
		tf.text = chars;

		if (fontCustomID == "")
			fontCustomID = fontFamily;
		bitmapFontFromTextField(tf, charMarginX, fontCustomID);
	}

	/**
		* This method will register a Bitmap Font based on each char that belongs to a regular flash TextField, rasterizing filters and color transforms as well.
		* 
		*@param	tf:openfl.text.TextField - The textfield that will be used to rasterize every char of the text property
		*@param	charMarginX:Int - The Float of pixels that each character should have as horizontal margin (negative values are allowed). Default value is 0.
		*@param	fontCustomID:String - A custom font family name indicated by the user. Helpful when using differnt effects for the same font. [Optional]
	 */
	static public function bitmapFontFromTextField(tf:openfl.text.TextField, charMarginX:Int = 0, fontCustomID:String = ""):Void {
		var charCol:Array<String> = tf.text.split("");
		var format:TextFormat = tf.defaultTextFormat;
		var fontFamily:String = format.font;
		var fontSize:Int = format.size;

		var oldAutoSize:String = tf.autoSize;
		tf.autoSize = TextFieldAutoSize.LEFT;

		var canvasData:BitmapData;
		var texture:Texture;
		var xml:Access;

		var myChar:String;

		_margin = 0;
		_preserveColor = true;

		_items = [];
		var itm:TextureItem;
		var itemsLen:Int;

		if (_canvas == null)
			_canvas = new Sprite();

		// Add the blank space char if not present;
		if (charCol.indexOf(" ") == -1)
			charCol.push(" ");

		var i:Int = charCol.length - 1;
		while (i > -1) {
			myChar = tf.text = charCol[i];
			drawItem(tf, Std.string(myChar.charCodeAt(0)));
			i--;
		}

		_currentLab = "";

		layoutChildren();

		canvasData = new BitmapData(Std.int(_canvas.width), Std.int(_canvas.height), true, 0x000000);
		canvasData.draw(_canvas);

		itemsLen = _items.length;

		xml = new Access(Xml.parse('<font></font>').firstElement());
		var infoNode:Access = new Access(Xml.parse('<info />').firstElement());
		infoNode.att.face = (fontCustomID == "") ? fontFamily : fontCustomID;
		infoNode.att.size = Std.string(fontSize);
		xml.x.addChild(infoNode.x);
		// var commonNode:Access = new Access(Xml.parse('<common alphaChnl="1" redChnl="0" greenChnl="0" blueChnl="0" />'));
		var commonNode:Access = new Access(Xml.parse('<common />').firstElement());
		commonNode.att.lineHeight = Std.string(fontSize);
		xml.x.addChild(commonNode.x);
		xml.x.addChild(Xml.parse('<pages><page id="0" file="texture.png" /></pages>').firstElement());
		var charsNode:Access = new Access(Xml.parse('<chars> </chars>').firstElement());
		charsNode.att.count = Std.string(itemsLen);
		var charNode:Access;

		for (k in 0...itemsLen) {
			itm = _items[k];

			// xml
			charNode = new Access(Xml.parse('<char page="0" xoffset="0" yoffset="0"/>').firstElement());
			charNode.att.id = itm.textureName;
			charNode.att.x = Std.string(itm.x);
			charNode.att.y = Std.string(itm.y);
			charNode.att.width = Std.string(itm.width);
			charNode.att.height = Std.string(itm.height);
			charNode.att.xadvance = Std.string(itm.width + 2 * charMarginX);
			charsNode.x.addChild(charNode.x);

			itm.graphic.dispose();
		}

		xml.x.addChild(charsNode.x);

		texture = Texture.fromBitmapData(canvasData);
		// TextField.registerBitmapFont(new BitmapFont(texture, xml));
		trace([fontFamily, fontCustomID]);
		TextField.registerCompositor(new BitmapFont(texture, xml.x), (fontCustomID == "") ? fontFamily : fontCustomID);

		_items.resize(0);
		_canvas.removeChildren();

		tf.autoSize = oldAutoSize;
		tf.text = charCol.join(",");

		_items = null;
		xml = null;
		_canvas = null;
		_currentLab = null;
	}
}
