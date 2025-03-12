package;
    import openfl.display.Sprite;
    import openfl.display.StageAlign;
    import openfl.display.StageScaleMode;
    
    import starling.core.Starling;
    
	class Startup extends Sprite
    {
        private var mStarling:Starling;
        
        public function new()
        {
            super();
            stage.color = 0x222222;
            stage.frameRate = 60;
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            
            mStarling = new Starling(DynAtlasSample, stage);
            mStarling.enableErrorChecking = false;
            mStarling.start();
        }
    }