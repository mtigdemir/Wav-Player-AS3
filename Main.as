package 
{

	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.media.Sound;
	import flash.utils.ByteArray;
	import org.as3wavsound.WavSound;
	import org.as3wavsound.WavSoundChannel;
	import org.as3wavsound.sazameki.format.wav.Wav;
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import flash.events.*;
	import flash.display.LoaderInfo;
	import flash.net.URLLoaderDataFormat;
	import flash.external.ExternalInterface;
	import flash.text.TextField;

	public class Main extends Sprite
	{

		public var snd:WavSound;
		public var sndChannel:WavSoundChannel;
		public var soundURL:String;
		public var debugMode:Boolean = false;
		public var urlRequest:URLRequest;
		public var loader:URLLoader;
		public var position:Number = 0;
		public var soundLength:String = "0:00";
		public var soundTotalLength:String = "";
		public var duration:Number = 0;

		public function Main()
		{
			try
			{
				var keyStr:String;
				var valueStr:String;
				var paramObj:Object = LoaderInfo(this.root.loaderInfo).parameters;
				for (keyStr in paramObj)
				{
					
					switch(keyStr) 
					{
						case "soundURL" : soundURL = String(paramObj[keyStr]);break;
						case "debugMode" : debugMode = true;break;
					}
					controls.debugTxt.appendText(keyStr + " : " +String(paramObj[keyStr]) +" \n");
				}
			}
			catch (error:Error)
			{
				controls.debugTxt.appendText(error.toString());
			}
			
			//Inıtialize
			initialize();
			urlRequest = new URLRequest(soundURL);
			loader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(Event.COMPLETE, onLoadComplete);
			loader.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			loader.load(urlRequest);

		}

		private function init(evt:Event = null):void
		{
			if (evt)
			{
				removeEventListener(Event.ADDED_TO_STAGE,init);
			}
			
			//Debug
			if (ExternalInterface.available)
			{
				ExternalInterface.call("console.log",root.loaderInfo.parameters.foo);
			}
		}
		
		
		// Initialize Player
		public function initialize():void
		{
			controls.mouseEnabled = false;
			
			if(debugMode == true)
			{
				controls.debugTxt.visible = true;
			}else {
				controls.debugTxt.visible = false;
			}
			
			//controls 
			//play / pause button
			controls.playPause.gotoAndStop("pause");

			controls.playPause.addEventListener(MouseEvent.MOUSE_OVER, playPauseOver);
			controls.playPause.addEventListener(MouseEvent.MOUSE_OUT, playPauseOut);
			controls.playPause.addEventListener(MouseEvent.MOUSE_DOWN, playPauseDown);
			controls.hitBar.addEventListener(MouseEvent.MOUSE_DOWN, hitDown);
			controls.hitBar.addEventListener(MouseEvent.MOUSE_UP, hitUp);

			/*Default Values*/
			controls.progressBar.scaleX = 0;
			controls.timeText.text = "Loading";
		}

		//Live
		private function live(e:Event)
		{
			var minutes:uint = Math.floor(sndChannel.position / 1000 / 60);
			var seconds:uint = Math.floor(sndChannel.position / 1000) % 60;
			controls.timeText.text = minutes + ':' + seconds;
		}

		private function onLoadComplete(ev:Event):void
		{
			controls.timeText.text = "Loaded";
			controls.playPause.gotoAndStop("play");
			snd = new WavSound(loader.data);
		}

		private function progressHandler(ev:ProgressEvent):void
		{
			controls.percentText.text =  "%" + (Math.floor((ev.bytesLoaded/ev.bytesTotal*100)));
		}

		/*------------------------*/
		function soundProgress(event:Event):void
		{
			var loadTime:Number = snd.bytesLoaded / snd.bytesTotal;
			var estimatedLength:int = Math.ceil(snd.length / (loadTime));
			var playbackPercent:uint = Math.round(100 * (sndChannel.position / estimatedLength));
			
			controls.progressBar.scaleX = playbackPercent / 100;
			duration = estimatedLength;
		}

		/*ACTIONS*/
		function hitDown(e:MouseEvent)
		{
			removeEventListener(Event.ENTER_FRAME, soundProgress);
			addEventListener(Event.ENTER_FRAME, soundScrub);
			stage.addEventListener(MouseEvent.MOUSE_UP, hitUp);

		}

		function hitUp(e:MouseEvent)
		{
			removeEventListener(Event.ENTER_FRAME, soundScrub);
			stage.removeEventListener(MouseEvent.MOUSE_UP, hitUp);
			addEventListener(Event.ENTER_FRAME, soundProgress);
		}
		
		/*Sound IN Live*/
		function soundScrub(e:Event)
		{
			var soundDist:Number = (mouseX - controls.x - controls.hitBar.x) / controls.hitBar.width;

			if (soundDist < 0)
			{
				soundDist = 0;
			}
			if (soundDist > 1)
			{
				soundDist = 1;
			}
			sndChannel.stop();
			
			sndChannel = snd.play(Math.floor(duration*soundDist));
			//This is important for repeat plays
			if(controls.playPause.currentFrame == 20)
			{
				controls.playPause.gotoAndStop("pause");
			}
			
			controls.progressBar.scaleX = soundDist;
		}	
		
		
		//Play - Pause Over
		function playPauseOver(e:MouseEvent):void{
			if(controls.playPause.currentFrame == 1) 
			{
				controls.playPause.gotoAndStop("pauseOver");
			}
			else 
			{
				controls.playPause.gotoAndStop("playOver");
			}
		}
			
		//Play - Pause Out 
		function playPauseOut(e:MouseEvent):void{
			if(controls.playPause.currentFrame == 10) 
			{
				controls.playPause.gotoAndStop("pause");
			}
			else 
			{
				controls.playPause.gotoAndStop("play");
			}
		}	
		
		//Play - Pause Down
		function playPauseDown(e:MouseEvent):void{
			
			if(controls.playPause.currentFrame == 10) 
			{
				position = sndChannel.position;
				controls.playPause.gotoAndStop("playOver");
				sndChannel.stop();
				
			}
			else 
			{
				controls.playPause.gotoAndStop("pauseOver");
				sndChannel = snd.play(position);
				addEventListener(Event.ENTER_FRAME, soundProgress);
				addEventListener(Event.ENTER_FRAME , live);
			}
		}
	}

}