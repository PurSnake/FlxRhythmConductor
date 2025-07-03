import flixel.FlxGame;
import openfl.Lib;
import openfl.display.FPS;

import flixel.addons.sound.FlxRhythmConductor;

class Main
{
	//public static var timeManager:FlxRhythmConductor;
	public static function main()
	{
		var stage = Lib.current.stage;
		var framerate:Int = 144;
		#if html5
		framerate = 60;
		#end
		//timeManager = new FlxRhythmConductor();
		var game = new FlxGame(1280, 720, PlayState, framerate, framerate, true, false);
		stage.addChild(game);
		game.addChild(new FPS(10, 10, 0xffffffff));
	}
}