
package nav.slideEngine
{
	import com.greensock.*;
	import com.greensock.easing.*;
	import com.greensock.plugins.*;
	
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageScaleMode;
	import flash.display.StageAlign;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.TextField;
	
	[SWF(frameRate=30, width=930, height=270)]
	public class slideEngine extends Sprite
	{
		/**
		 * Stores the raw XML Object Data
		 */
		public var XMLData:XML;
		/**
		 * Stores the XML for Page Data
		 */
		public var XMLPages:XML;
		/**
		 * Stores XML for Settings
		 */
		public var XMLSettings:XML;
		/**
		 * Settings Storage for the Application
		 */
		public static var Settings:Object;
		
		/**
		 * Pages Storage array
		 */
		public static var Pages:Array;

		private var bgLoader:Loader;
		private var bgSprite:Sprite;
		private var maskLoader:Loader;
		private var _str:StringHelper = new StringHelper();		
		private var TotalObjects:Number = 0;
		private var LoadedObjects:Number = 0;
		private var tf:TextField;
		
		private static var InMotion:Boolean = false;
		private static var TotalPages:Number;
		private static var LoadedPages:Number = 0;
		
		public var Elements:Array;
		public static var ActiveID:Number = 0;
		public static var StageWidth:Number;
		public static var StageHeight:Number;
		
 
		
		/**
		 * An XML based Flash Engine for Displaying a slideshow of Flash Animations for Websites
		 * @author Kyle Harrison
		 * @copyright Navigator Multimedia 2011
		 * @package nav.slideEngine
		 * @version 1.0.0
		 */
		public function slideEngine()
		{
			// We have first entered the slideEngine
			trace("Wecome to slideEngine by Kyle Harrison");
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			TweenPlugin.activate([BlurFilterPlugin]);
			
			tf = new TextField();
			addChild(tf);
			tf.text = "Test";
			tf.textColor = 0x000000;
			
			
			Elements = new Array();
			Pages = new Array();
			
			StageWidth = stage.stageWidth;
			StageHeight = stage.stageHeight;
			
			var xmlLoader:URLLoader = new URLLoader();
			var XMLPath:URLRequest = new URLRequest("pages.xml");
			trace("XMLPath: " + XMLPath.url.toString());
			xmlLoader.addEventListener(Event.COMPLETE, ParseXML);
			try {
				tf.text = "Loading pages.xml";
				xmlLoader.load(XMLPath);
			} catch(e:Error) {
				trace("pages.xml cannot be found");
				tf.text = "Cannot find "+e.toString();
			}
		}
		
		private function ParseXML(e:Event):void {
			removeChild(tf);
			XMLData = new XML(e.target.data);
			XMLPages = new XML(XMLData.pages);
			Settings = new Object();
			// Set the Settings
			
			// Defaults
			Settings.root = "";
			Settings.swfroot = Settings.root;
			Settings.imgroot = Settings.root;
			Settings.backgroundOffset = null;
			Settings.mask = null;
			Settings.motionBlur = false;
			Settings.background = null;
			Settings.shiftTime = 1;
			Settings.resetTime = 2;
			Settings.loop = true;
			
			// All settings are optional, but if a setting exists, attempt to override the default value
			if(XMLData.settings) {
				trace("Settings Exists, lets use it");
				if(_str.trim(XMLData.settings.attribute("root"), " ") != "") 					Settings.root = XMLData.settings.attribute("root");
				if(_str.trim(Settings.root+XMLData.settings.attribute("swfroot"), " ") != "") 	Settings.swfroot = Settings.root+XMLData.settings.attribute("swfroot"); 		else Settings.swfroot = Settings.root; 
				if(_str.trim(XMLData.settings.attribute("imgroot"), " ") != "") 				Settings.imgroot = Settings.root+XMLData.settings.attribute("imgroot"); 		else Settings.imgroot = Settings.root;
				if(_str.trim(XMLData.settings.attribute("background-offset"), " ") != "") 		Settings.backgroundOffset = XMLData.settings.attribute("background-offset");
				if(_str.trim(XMLData.settings.attribute("mask"), " ") != "") 					Settings.mask = XMLData.settings.attribute("mask");
				if(_str.trim(XMLData.settings.attribute("motionBlur"), " ") != "")				Settings.motionBlur = XMLData.settings.attribute("motionBlur");
				if(_str.trim(XMLData.settings.attribute("background"), " ") != "")				Settings.background = XMLData.settings.attribute("background");
				if(_str.trim(XMLData.settings.attribute("shiftTime"), " ") != "")				Settings.shiftTime = parseFloat(XMLData.settings.attribute("shiftTime"));
				if(_str.trim(XMLData.settings.attribute("resetTime"), " ") != "")				Settings.resetTime = parseFloat(XMLData.settings.attribute("resetTime"));
				if(_str.trim(XMLData.settings.attribute("loop"), " ") != "")					Settings.loop = XMLData.settings.attribute("loop");
			}
			
			trace("Mask: " + XMLData.settings.attribute("mask"));
			
			ParseSettings();
			ParsePages();
		}
		
		private function ParseSettings():void {
			if(Settings.background == null) {
				// Dont do anything
			} else if(Settings.background.charAt(0) == "#") {
				// This is a hex value, create a opaque bg
				bgSprite = new Sprite();
				var color:String = Settings.background;
				color = color.replace(new RegExp("#"), "");
				var oct:Number = parseInt(color, 16);
				trace("BG COLOR: " + oct);
				bgSprite.graphics.beginFill(oct, 1);
				bgSprite.graphics.drawRect(0, 0, StageWidth, StageHeight);
				bgSprite.graphics.endFill();
			} else {
				// Must be an image
				trace("Loading an Image for the Background...");
				trace(Settings.imgroot+Settings.background);
				TotalObjects++;
				bgLoader = new Loader();
				bgLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, CreateBGImage);
				bgLoader.load(new URLRequest(Settings.imgroot+Settings.background));
			}
			
			if(Settings.mask && Settings.mask != null) {
				TotalObjects++;
				maskLoader = new Loader();
				maskLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, CreateMask);
				maskLoader.load(new URLRequest(Settings.imgroot+Settings.mask));
			}
		}
		
		private function ParsePages():void {
			trace("Parsing Pages");
			var p:String;
			var ref:Object;
			TotalPages = 0;
			for(p in XMLPages.page) {
				TotalPages++;
				trace("Creating Page " + TotalPages);
				Object["page"+TotalPages] = new Page(TotalPages, Settings.swfroot+XMLPages.page[p].attribute("src"), XMLPages.page[p].attribute("href"));
			}
			
			this.addEventListener(Event.ENTER_FRAME, PreLoader);
		}
		
		private function PreLoader(e:Event):void {
			
			if(TotalPages == LoadedPages) {
				trace("Loading Completed, Proceeding");
				this.removeEventListener(Event.ENTER_FRAME, PreLoader);
				Render();
			}
			
		}
		
		private function CreateBGImage(e:Event):void {
			
			if(Settings.backgroundOffset != null) {
				var offset:Array = Settings.backgroundOffset.split(",");
				if(offset[0].charAt(0) == "-") bgLoader.x = bgLoader.x-(offset[0].replace("-", ""));
				else bgLoader.x = bgLoader.x+offset[0];
				if(offset[1].charAt(0) == "-") bgLoader.y = bgLoader.y-(offset[1].replace("-", ""));
				else bgLoader.y = bgLoader.y+offset[1];
			}
			
		}
		
		private function CreateMask():void {
			
		}
		
		
		private function Render():void {
			// Render BG Image First, Then Pages, Then Dots, Then Mask.
			// BG Image is bgLoader and Mask is maskLoader, add those children beginning and last respectfully
			
			if(Settings.background != null && Settings.background.charAt(0) == "#") addChild(bgSprite); 
			else if(Settings.background != null && Settings.background.charAt(0) != "#") addChild(bgLoader);
			
			// Adding them in order, not in the order of loaded
			var NewX:Number = 0;
			var addedPages:Number = 1;
			while(addedPages <= TotalPages) {
				for(var p in Pages) {
					trace("Looking for ID: " + addedPages + ", is this the one? " + Pages[p][0]);
					if(Pages[p][0] == addedPages) {
						trace("Hit!");
						Pages[p][1].x = NewX;
						Pages[p][4].x = NewX;
						addChild(Pages[p][1]);
						addChild(Pages[p][4]);
						NewX += StageWidth;
						addedPages++;
						trace("Testing: " + NewX + "::" + StageWidth);
						break;
					}
				}
			}
			
			
			Start();
		}
		
		/**
		 * Adds an Object to the Render Queue
		 */
		public static function AddToQueue(id:Number, swf:Object, mc:Object, ref:Object, lnk:Sprite):Boolean {
			trace("Adding to Queue: \n SWF: " + swf + "\n MC: " + mc);
			if(Pages.push(
					new Array(id, swf, mc, ref, lnk)
				))	{
				LoadedPages++;
				trace("TotalPages: " + TotalPages);
				trace("LoadedPages: " + LoadedPages);
				return true;
			}
			else return false;
		}
		
		public static function Next():void {
			trace(" ---- 1. Finding Next...");
			FindNext(); // This will set the ActiveID that we can use
			trace(" ---- 3. Goingt to Next...");
			GotoNext(); // This Goes To It
		}
		
		private function Start():void {
			ActiveID = 1;
			StartClip();
		}
		
		private static function StartClip():void {
			for(var p in Pages) {
				trace("Looking for id of "+ActiveID+", is this it: " + Pages[p][0]);
				if(Pages[p][0] == ActiveID) {
					trace("This is the one... Playing " + Pages[p][0]);
					Pages[p][3].playFromBeginning();
					break;
				}
			}
		}
		
		private static function FinishedMotion():void {
			InMotion = false;
			ResetAll();
			StartClip();
		}
		
		private static function ShiftLeft():void {
			InMotion = true;	
			
			//trace("Shift Timings: \n\n - ShiftTime" + Settings.shiftTime +"\n - BlurIn: " + (Settings.shiftTime*0.7) + "\n - BlurIn Delay: " + (Settings.shiftTime*0.1) + "\n - BlurOut: " + (Settings.shiftTime*0.3) + "\n - BlurOut Delay: " + (Settings.shiftTime*0.7));
			
			for(var p in Pages) {
				TweenLite.to(
					Pages[p][1], 
					Settings.shiftTime, 
					{
						x:(Pages[p][1].x-StageWidth), 
						ease:Expo.easeInOut,
						onComplete:FinishedMotion
					}
				);
				TweenLite.to(
					Pages[p][4], 
					Settings.shiftTime, 
					{
						x:(Pages[p][4].x-StageWidth), 
						ease:Expo.easeInOut
					}
				);
				if(Settings.motionBlur == "true") {
					TweenLite.to(
						Pages[p][1],
						(Settings.shiftTime*0.7),
						{
							blurFilter:{blurX:25},
							overwrite:false,
							delay:(Settings.shiftTime*0.1)
						}
					);
					TweenLite.to(
						Pages[p][1],
						(Settings.shiftTime*0.3),
						{
							blurFilter:{blurX:0},
							overwrite:false,
							delay:(Settings.shiftTime*0.7)
						}
					);
				}
			}
		}
		
		private static function ShiftRight():void {
			InMotion = true;
			for(var p in Pages) {
				TweenLite.to(
					Pages[p][1], 
					Settings.shiftTime, 
					{
						x:(Pages[p][1].x+StageWidth), 
						ease:Expo.easeInOut,
						onComplete:FinishedMotion
					}
				);
				TweenLite.to(
					Pages[p][4], 
					Settings.shiftTime, 
					{
						x:(Pages[p][4].x-StageWidth), 
						ease:Expo.easeInOut
					}
				);
				if(Settings.motionBlur == "true") {
					TweenLite.to(
						Pages[p][1],
						(Settings.shiftTime*0.7),
						{
							blurFilter:{blurX:25},
							overwrite:false,
							delay:(Settings.shiftTime*0.1)
						}
					);
					TweenLite.to(
						Pages[p][1],
						(Settings.shiftTime*0.3),
						{
							blurFilter:{blurX:0},
							overwrite:false,
							delay:(Settings.shiftTime*0.7)
						}
					);
				}
			}
		}
		
		private static function GotoFirst():void {
			InMotion = true;
			var TotalWidth:Number = (TotalPages*StageWidth)-StageWidth;
			trace((TotalPages*StageWidth)+" / " +TotalWidth);
			for(var p in Pages) {
				TweenLite.to(
					Pages[p][1], 
					Settings.resetTime, 
					{
						x:(Pages[p][1].x+TotalWidth), 
						ease:Expo.easeInOut,
						onComplete:FinishedMotion
					}
				);
				TweenLite.to(
					Pages[p][4], 
					Settings.resetTime, 
					{
						x:(Pages[p][4].x+TotalWidth), 
						ease:Expo.easeInOut
					}
				);
				if(Settings.motionBlur == "true") {
					TweenLite.to(
						Pages[p][1],
						(Settings.resetTime*0.7),
						{
							blurFilter:{blurX:25},
							overwrite:false,
							delay:(Settings.resetTime*0.3)
						}
					);
					TweenLite.to(
						Pages[p][1],
						(Settings.resetTime*0.3),
						{
							blurFilter:{blurX:0},
							overwrite:false,
							delay:(Settings.resetTime*0.7)
						}
					);
				}
			}
		}
		
		private static function FindNext():void {
			trace(" ---- 2. Finding Next... Now");
			trace(ActiveID + " / " + (TotalPages));
			if(ActiveID >= (TotalPages)) ActiveID = 1;
			else ActiveID++;
		}
		
		private static function ResetAll():void {
			for(var p in Pages) {
				Pages[p][3].InitCheckFinished();
				Pages[p][3].stopAtBeginning();
			}
		}
		
		private static function GotoNext():void {
			trace(" ---- 4. Going to Next...");
			if(ActiveID == 1) {
				if(Settings.loop != "false") GotoFirst();
			}
			else if(ActiveID <= TotalPages) ShiftLeft();
		}
		
		
	}
}