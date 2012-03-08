package nav.slideEngine
{
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	
	public class Page extends MovieClip
	{
		private var Src:String;
		private var Lnk:String;
		private var SWF:Loader;
		private var MC:MovieClip;
		private var Btn:Sprite;
		public var Loaded:Boolean = false;
		public var id:Number;
		
		//private var LinkShape:Shape;
		
		public function Page(NewID:Number, Source:String, Link:String)
		{
			id = NewID;
			Src = Source;
			Lnk = Link;
			
			trace("Created Page with Source: " + Src + "\n and HREF: " + Lnk);
			SWF = new Loader;
			SWF.contentLoaderInfo.addEventListener(Event.COMPLETE, AddSWF);
			SWF.load(new URLRequest(Src));
			
			BuildLink();
		}
		
		public function BuildLink():void {
			Btn = new Sprite();
			Btn.graphics.lineStyle(1, 0x000000, 0);
			Btn.graphics.beginFill(0xFFFFFF, 0);
			Btn.graphics.drawRect(0, 0, slideEngine.StageWidth, slideEngine.StageHeight);
			Btn.graphics.endFill();
			if(Lnk != "") {
				Btn.buttonMode = true;
				Btn.useHandCursor = true;
				Btn.addEventListener(MouseEvent.CLICK, LinkMe);
			}
		}
		
		private function AddSWF(e:Event):void {
			MC = SWF.content as MovieClip;
			MC.gotoAndStop(1);
			slideEngine.AddToQueue(id, SWF, MC, this, Btn);
			MC.isDone = false;
			MC.addEventListener(Event.ENTER_FRAME, CheckFinished);
			Render();
		}
		
		private function CheckFinished(e:Event):void {
			if(e.currentTarget.isDone == true) {
				e.currentTarget.gotoAndStop("done");
				e.currentTarget.isDone = false;
				MC.removeEventListener(Event.ENTER_FRAME, CheckFinished);
				slideEngine.Next();
			} 
		}
		
		private function LinkMe(e:MouseEvent):void {
			trace("Going to: " + Lnk);
			navigateToURL(new URLRequest(slideEngine.Settings.root+Lnk));
		}
		
		public function Render():void {
			
			if(Lnk != "" && Lnk != null) {
				trace("Rendering... "+Lnk);
				
			}
		}
		
		public function InitCheckFinished():void {
			MC.addEventListener(Event.ENTER_FRAME, CheckFinished);
		}
		
		public function stopAtBeginning():void {
			MC.gotoAndStop(1);
		}
		
		public function playFromBeginning():void {
			MC.gotoAndPlay(1);
		}
		
		public function playFromFrame(frame:Number):void {
			MC.gotoAndPlay(frame);
		}
		
		public function stopAtFrame(frame:Number):void {
			MC.gotoAndStop(frame);
		}
		
		
	}
}