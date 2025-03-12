package;

import starling.rendering.VertexData;
import starling.text.TextOptions;
import starling.text.TextFormat;

import com.emibap.textureAtlas.DynamicAtlas;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.text.Font;
import openfl.Assets;
import openfl.errors.Error;
import openfl.Lib.getTimer;
import openfl.Lib.setTimeout;

import starling.core.Starling;
import starling.display.Image;
import starling.events.EnterFrameEvent;
import starling.text.BitmapFont;
import starling.text.TextField;
import starling.textures.Texture;
import starling.utils.Color;
import starling.display.MovieClip;
import starling.textures.TextureAtlas;
import starling.display.Sprite;

class DynAtlasSample extends Sprite {
	public function new() {
		super();
		init();
	}

	private function init():Void {
		addClipsFromContainer();
		addTextFields();
	}

	/**
	 * This method creates a Dynamic Atlas from a MovieClip Container and adds some Display Objects to the starling stage
	 * 
	 * It assumes that a class named SheetMC is a MovieClip which has been defined in a swc. (See the sample_for_atlas.fla for reference)
	 */
	private function addClipsFromContainer():Void {
		var mc:SheetMC = new SheetMC();
		var t1:UInt = getTimer();
		var atlas:TextureAtlas = DynamicAtlas.fromMovieClipContainer(mc, .5, 0, true, true);
		var total:UInt = getTimer() - t1;
		// trace("atlas:", atlas);
		trace(total + " msecs elapsed while converting...");
		var boy_mc:MovieClip = new MovieClip(atlas.getTextures("boy"), 60);
		boy_mc.x = boy_mc.y = 10;
		addChild(boy_mc);
		Starling.currentJuggler.add(boy_mc);

		var btnSkin:Image = new Image(atlas.getTextures("buttonSkin")[0]);
		btnSkin.x = 30;
		btnSkin.y = 80;
		addChild(btnSkin);
	}

	/**
	 * This method registers a number of Dynamically generated bitmap fonts and adds texfields to the starling stage
	 * 
	 * For this method to work, you need to have the following fonts installed and embedded Into a swc (Class names are defined inside the sample_for_atlas.fla file):
	 * - Verdana
	 * - Comic Sans
	 */
	private function addTextFields():Void {
		try {
			var embeddedFont1:Font = Assets.getFont("assets/Verdana.ttf");
			var embeddedFont2:Font = Assets.getFont("assets/ComicSansMSBold.ttf");

			var chars2Add:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
			chars2Add += chars2Add.toLowerCase() + ",.-_!?1234567890: ";

			var cont:TextContainer = new TextContainer();

			DynamicAtlas.bitmapFontFromString(chars2Add, embeddedFont1.fontName, 16, false, false, -2);
			DynamicAtlas.bitmapFontFromString(chars2Add, "_sans", 16, false, false, -2);
			// Don't use bitmapFontFromTextField, it won't work
			DynamicAtlas.bitmapFontFromString("ABCDEFGHIJKLMNOPQRSTUVWXYZ", embeddedFont2.fontName, 20, false, false, 0);

			var textFmt:TextFormat = new TextFormat(embeddedFont1.fontName, 16, 0xFF0000);
			textFmt.bold = true;
			var embedded_tf:TextField = new TextField(300, 100, "Here is some dynamically generated text using an embedded Bitmap Font", textFmt);
			embedded_tf.x = 150;
			embedded_tf.y = 10;
			embedded_tf.autoScale = true;
			embedded_tf.border = true;
			addChild(embedded_tf);

			var textFmt2:TextFormat = new TextFormat("_sans", 16, 0x00FF00);
			textFmt2.bold = false;
			var system_tf:TextField = new TextField(300, 100, "Here is some dynamically generated text using a system Bitmap Font.", textFmt2);
			system_tf.x = embedded_tf.x;
			system_tf.y = embedded_tf.y + embedded_tf.height;
			system_tf.autoScale = true;
			system_tf.border = true;
			addChild(system_tf);

			var textFmt3:TextFormat = new TextFormat(embeddedFont2.fontName, 16, 0x00FF00);
			var filtered_tf:TextField = new TextField(300, 100, "AND ONE HELLUVA (UN)FILTERED TEXT", textFmt3);
			// the native bitmap font size, no scaling
			textFmt3.size = BitmapFont.NATIVE_SIZE;
			// use white to use the texture as it is (no tInting)
			textFmt3.color = Color.WHITE;
			filtered_tf.format = textFmt3;
			filtered_tf.x = embedded_tf.x;
			filtered_tf.y = system_tf.y + system_tf.height;
			filtered_tf.border = true;
			addChild(filtered_tf);
		} catch (e:Error) {
			trace("There was an error in the creation of one of the Bitmap Fonts. Please check if the dimensions of your clip exceeded the maximun allowed texture size. -",
				e.message);
		}
	}
}
