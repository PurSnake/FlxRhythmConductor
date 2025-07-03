import haxe.PosInfos;
import flixel.tweens.misc.NumTween;
import flixel.sound.FlxSound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.input.keyboard.FlxKey;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.addons.sound.FlxRhythmConductor;
import flixel.addons.sound.FlxRhythmConductorUtil;
import flixel.addons.sound.MusicTimeChangeEvent;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.geom.Point;

using flixel.addons.sound.FlxRhythmConductorUtil;

class PlayState extends FlxState
{
	var musicPath:String = "assets/music/third-sanctuary.ogg";

	var haxeFlixelLogoLeft:FlxSprite;
	var haxeFlixelLogoRight:FlxSprite;

	var infoText:FlxText;

	override function create()
	{
		bgColor = FlxColor.GRAY.getDarkened(0.45);

		var gridSize:Int = 64;
		var bmd:BitmapData = FlxGridOverlay.createGrid(gridSize, gridSize, FlxG.width * 2, FlxG.height * 2, true, 0xFF292929, FlxColor.TRANSPARENT);

		var textureWidth = gridSize * 20;
		var textureHeight = gridSize * 20; 
		var croppedBmd = new BitmapData(textureWidth - 1, textureHeight - 1, true, 0x0);
		croppedBmd.copyPixels(bmd, new Rectangle(0, 0, textureWidth - 1, textureHeight - 1), new Point(0, 0));

		var gridBackdrop = new FlxBackdrop(croppedBmd, XY);
		gridBackdrop.velocity.set(50, 50);
		add(gridBackdrop);

		haxeFlixelLogoLeft = new FlxSprite().loadGraphic(null); // load HaxeFlixel logo
		add(haxeFlixelLogoLeft);
		haxeFlixelLogoLeft.scale.set(2.5, 2.5);
		haxeFlixelLogoLeft.screenCenter();
		haxeFlixelLogoLeft.x -= 250;

		haxeFlixelLogoRight = new FlxSprite().loadGraphic(null); // load HaxeFlixel logo
		add(haxeFlixelLogoRight);
		haxeFlixelLogoRight.scale.set(2.5, 2.5);
		haxeFlixelLogoRight.screenCenter();
		haxeFlixelLogoRight.x += 250;

		infoText = new FlxText(10, 0, 0, "Hello", 24);
		infoText.text = 'Boo';
		add(infoText);
		infoText.y = FlxG.height - infoText.textField.textHeight - 10;

		final bindText:FlxText = new FlxText(10, 10 + 20, FlxG.width, "What's up, World!?", 18);
		bindText.text = [
			"Z - Reset Conductor",
			"X - Reset Conductor and destroy FlxG.sound.music",
			"C, V, B, N, M, G - Load different tests",
			"A/LEFT_D/RIGHT - change Conductor's target sound pitch",
			"R - reset Conductor's target sound pitch to 1",
			"J/L - scroll Conductor's target sound time",
			"SPACE - pause/resume Conductor's target sound",
			"1-9 - Set time to at the exact time, according that 9 it's end time",
		].join(" | ");
		add(bindText);
		bindText.active = false;
	}

	function loadTest1():Void
	{
		musicPath = "assets/music/third-sanctuary.ogg";
		haxeFlixelLogoLeft.angle = haxeFlixelLogoRight.angle = 0;
		FlxRhythmConductor.reset();
		FlxG.sound.playMusic(musicPath, 1);
		FlxRhythmConductor.instance.onBeatHit.add(step ->
		{
			haxeFlixelLogoLeft.scale.set(4, 4);
			FlxG.sound.play("assets/sounds/metronome.ogg");
		});
		FlxRhythmConductor.instance.onMeasureHit.add(beat ->
		{
			haxeFlixelLogoRight.scale.set(5, 5);
		});
		FlxRhythmConductor.instance.loadMetaFromFilePath(musicPath);
	}

	function loadTest2():Void
	{
		musicPath = "assets/music/its_t_v_time.ogg";
		haxeFlixelLogoLeft.angle = haxeFlixelLogoRight.angle = 0;
		FlxRhythmConductor.reset();
		FlxG.sound.playMusic(musicPath, 1);
		FlxRhythmConductor.instance.loadMetaFromFilePath(musicPath);
		FlxRhythmConductor.instance.onBeatHit.add(step ->
		{
			haxeFlixelLogoLeft.angle += 15;
			FlxG.sound.play("assets/sounds/metronome.ogg");
		});
		FlxRhythmConductor.instance.onMeasureHit.add(beat ->
		{
			haxeFlixelLogoRight.angle += 15;
		});
	}

	function loadTest3():Void
	{
		musicPath = "assets/music/its_t_v_time_with_no_timeChanges_file.ogg";
		haxeFlixelLogoLeft.angle = haxeFlixelLogoRight.angle = 0;
		FlxRhythmConductor.reset();
		FlxG.sound.playMusic(musicPath, 1);
		FlxRhythmConductor.instance.onBeatHit.add(step ->
		{
			haxeFlixelLogoLeft.scale.set(4, 4);
			FlxG.sound.play("assets/sounds/metronome.ogg");
		});
		FlxRhythmConductor.instance.onMeasureHit.add(beat ->
		{
			haxeFlixelLogoRight.scale.set(5, 5);
		});
		FlxRhythmConductor.instance.loadMetaFromFilePath(musicPath);
	}

	function loadTest4():Void
	{
		musicPath = "assets/music/phone_call.ogg";
		haxeFlixelLogoLeft.angle = haxeFlixelLogoRight.angle = 0;
		FlxRhythmConductor.reset();
		FlxG.sound.playMusic(musicPath, 1);
		FlxRhythmConductor.instance.onBeatHit.add(step ->
		{
			haxeFlixelLogoLeft.scale.set(4, 4);
			FlxG.sound.play("assets/sounds/metronome.ogg");
		});
		FlxRhythmConductor.instance.onMeasureHit.add(beat ->
		{
			haxeFlixelLogoRight.scale.set(5, 5);
		});
		FlxRhythmConductor.instance.loadMetaFromFilePath(musicPath);
	}

	function loadTest5():Void
	{
		musicPath = "assets/music/trouble_maker.ogg";
		haxeFlixelLogoLeft.angle = haxeFlixelLogoRight.angle = 0;
		FlxRhythmConductor.reset();
		FlxG.sound.playMusic(musicPath, 1);
		FlxRhythmConductor.instance.onBeatHit.add(step ->
		{
			haxeFlixelLogoLeft.scale.set(4, 4);
			FlxG.sound.play("assets/sounds/metronome.ogg");
		});
		FlxRhythmConductor.instance.onMeasureHit.add(beat ->
		{
			haxeFlixelLogoRight.scale.set(5, 5);
		});
		FlxRhythmConductor.instance.loadMetaFromFilePath(musicPath);
	}

	function loadTest6():Void
	{
		musicPath = "assets/music/bpmtest.ogg";
		haxeFlixelLogoLeft.angle = haxeFlixelLogoRight.angle = 0;
		FlxRhythmConductor.reset();
		FlxG.sound.playMusic(musicPath, 1);
		FlxRhythmConductor.instance.onBeatHit.add(step ->
		{
			haxeFlixelLogoLeft.scale.set(4, 4);
			FlxG.sound.play("assets/sounds/metronome.ogg");
		});
		FlxRhythmConductor.instance.onMeasureHit.add(beat ->
		{
			haxeFlixelLogoRight.scale.set(5, 5);
		});
		FlxRhythmConductor.instance.loadMetaFromFilePath(musicPath);
	}

	public override function update(elapsed:Float)
	{
		infoText.text = "";
		if (FlxG.keys.justPressed.Z)
		{
			// Kills FlxRhythmConductor, but doesn't kill music, so it will just load defualt timeChange and track time!
			FlxRhythmConductor.reset();
		}

		if (FlxG.keys.justPressed.X)
		{
			// Kills FlxRhythmConductor, but doesn't kill music, so it will just load defualt timeChange and track time!
			FlxRhythmConductor.reset();
			FlxG.sound.music?.destroy();
			FlxG.sound.music = null;
		}

		if (FlxG.keys.justPressed.C)
			loadTest1();

		if (FlxG.keys.justPressed.V)
			loadTest2();

		if (FlxG.keys.justPressed.B)
			loadTest3();

		if (FlxG.keys.justPressed.N)
			loadTest4();

		if (FlxG.keys.justPressed.M)
			loadTest5();

		if (FlxG.keys.justPressed.G)
			loadTest6();

		var conductor = FlxRhythmConductor.instance;

		var target = conductor.target;
		if (target != null)
		{
			if (haxeFlixelLogoLeft.scale.x != 2.5)
			{
				final scaleMult:Float = FlxMath.lerp(2.5, haxeFlixelLogoLeft.scale.x, Math.exp(-elapsed * 10));
				haxeFlixelLogoLeft.scale.set(scaleMult, scaleMult);
			}

			if (haxeFlixelLogoRight.scale.x != 2.5)
			{
				final scaleMult:Float = FlxMath.lerp(2.5, haxeFlixelLogoRight.scale.x, Math.exp(-elapsed * 15));
				haxeFlixelLogoRight.scale.set(scaleMult, scaleMult);
			}

			if (FlxG.keys.anyPressed([A, LEFT]) && target.pitch - elapsed > 0.0001)
				target.pitch -= elapsed;

			if (FlxG.keys.anyPressed([D, RIGHT]) && target.pitch + elapsed < 100)
				target.pitch += elapsed;

			if (FlxG.keys.pressed.J)
				target.time -= elapsed * 1000;

			if (FlxG.keys.pressed.L)
				target.time += elapsed * 1000;

			if (FlxG.keys.justPressed.R)
				target.pitch = 1;

			if (FlxG.keys.justPressed.SPACE)
			{
				if (target.playing)
					target.pause()
				else
					target.resume();
			}

			var justPressed = FlxG.keys.firstJustPressed();
			if (FlxMath.inBounds(justPressed, FlxKey.ONE, FlxKey.NINE))
				target.time = FlxMath.remapToRange(justPressed, FlxKey.ONE, FlxKey.NINE, 0, conductor.musicLength);
		}

		super.update(elapsed);
		conductor.update(null);

		if (target != null)
			infoText.text += 'Current target pitch: ${target.pitch}\n';
		else
			infoText.text += 'NO SOUND INITIALIZED!\nFlxRhythmConductor will be updated in real time\n\n';

		infoText.text += 'Current bpm: ${conductor.currentBpm}\n';
		infoText.text += 'Current step: ${conductor.currentStep}\n';
		infoText.text += 'Current beat: ${conductor.currentBeat}\n';
		infoText.text += 'Current time signature: ${conductor.timeSignatureNumerator}/${conductor.timeSignatureDenominator}\n';
		infoText.text += 'Current measure: ${conductor.currentMeasure}\n';
		infoText.text += 'Current musicPosition: ${conductor.musicPosition}\n';
		infoText.text += 'Current music: $musicPath';
		infoText.y = FlxG.height - infoText.textField.textHeight - 10;
	}
}
