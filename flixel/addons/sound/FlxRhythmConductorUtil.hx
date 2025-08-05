package flixel.addons.sound;

import flixel.addons.sound.FlxRhythmConductor;
import flixel.addons.sound.MusicTimeChangeEvent;
import flixel.addons.sound.MusicTimeChangeEvent.MusicTimeChangeData;
import flixel.addons.sound.FlxTimeSignature;
import openfl.utils.Assets;
import haxe.Json;

@:nullSafety
class FlxRhythmConductorUtil
{
	public inline static function clamp(value:Float, min:Float, end:Float):Float
	{
		return min > value ? min : end < value ? end : value;
	}

	public inline static function getStepsPerMs(bpm:Float):Float
	{
		return getBeatPerMs(bpm) * FlxRhythmConductorConstants.STEPS_PER_BEAT;
	}

	public inline static function getBeatPerMs(bpm:Float):Float
	{
		return bpm / FlxRhythmConductorConstants.MS_PER_MIN;
	}

	public inline static function getStepsPerMeasure(timeSignNum:FlxTimeSignature, timeSignDec:FlxTimeSignature):Int
	{
		return Math.floor(getTimeSignatureFactor(timeSignNum, timeSignDec) * FlxRhythmConductorConstants.STEPS_PER_BEAT * FlxRhythmConductorConstants.STEPS_PER_BEAT);
	}

	public inline static function getBeatsPerMeasure(timeSignNum:FlxTimeSignature, timeSignDec:FlxTimeSignature):Float
	{
		return getStepsPerMeasure(timeSignNum, timeSignDec) / FlxRhythmConductorConstants.STEPS_PER_BEAT;
	}

	public inline static function getStepLengthMs(bpm:Float):Float
	{
		return getBeatLengthMs(bpm) / FlxRhythmConductorConstants.STEPS_PER_BEAT;
	}

	public inline static function getBeatLengthMs(bpm:Float):Float
	{
		return FlxRhythmConductorConstants.MS_PER_MIN / bpm;
	}

	public inline static function getMeasureLengthMs(bpm:Float, timeSignNum:FlxTimeSignature, timeSignDec:FlxTimeSignature):Float
	{
		return getBeatLengthMs(bpm) * getTimeSignatureFactor(timeSignNum, timeSignDec) * FlxRhythmConductorConstants.BEATS_PER_MEASURE;
	}

	public inline static function getTimeSignatureFactor(timeSignNum:FlxTimeSignature, timeSignDec:FlxTimeSignature):Float
	{
		return timeSignNum / timeSignDec;
	}

	public inline static function loadMetaFromFilePath(rhythmConductor:FlxRhythmConductor, musicPath:String)
	{
		final arrayOfChanges:Array<MusicTimeChangeEvent> = getTimeChangesFromFile(musicPath);
		loadMeta(rhythmConductor, arrayOfChanges);
	}

	public inline static function loadMeta(rhythmConductor:FlxRhythmConductor, arrayOfChanges:Array<MusicTimeChangeEvent>)
	{
		rhythmConductor.setupTimeChanges(arrayOfChanges);
	}

	public static function getTimeChangesFromFile(path:String):Array<MusicTimeChangeEvent>
	{
		final fileMetaPath:String = getMusicMetaPath(path);
		if (Assets.exists(fileMetaPath, TEXT))
		{
			try
			{
				final parsedData:Null<Array<MusicTimeChangeData>> = Json.parse(Assets.getText(fileMetaPath));
				final arrayOfChanges:Array<MusicTimeChangeEvent> = parseTimeChanges(parsedData);

				if (arrayOfChanges.length == 0)
					FlxG.log.warn('[WARNING] No avalaible timeChanges found in .${FlxRhythmConductorConstants.META_FILE_EXT} file for $path');

				return arrayOfChanges;
			}
			catch (e)
				FlxG.log.error('[ERROR] Can\t load .${FlxRhythmConductorConstants.META_FILE_EXT} file for $path');
		}
		FlxG.log.error('[ERROR] Can\'t load timeChanges for $path');
		return [];
	}
	public static function parseTimeChanges(data:Null<Array<MusicTimeChangeData>>):Array<MusicTimeChangeEvent>
	{
		final arrayOfChanges:Array<MusicTimeChangeEvent> = [];
		var lastBPM:Float = FlxRhythmConductorConstants.BPM;
		var lastTSN:FlxTimeSignature = FlxRhythmConductorConstants.TIME_SIGNATURE_NUM;
		var lastTSD:FlxTimeSignature = FlxRhythmConductorConstants.TIME_SIGNATURE_DEN;
		if (data != null && data.length > 0)
			for (data in data)
			{
				lastBPM = data.bpm ?? lastBPM;
				lastTSN = data.tsn ?? lastTSN;
				lastTSD = data.tsd ?? lastTSD;
				arrayOfChanges.push(new MusicTimeChangeEvent(data.t, lastBPM, lastTSN, lastTSD, data.d, data.ease));
			}

		return arrayOfChanges;
	}

	private static final EXT_REGEX = new EReg("\\.([^.]+)$", "");

	public static inline function getMusicMetaPath(musicPath:String):String
		return (EXT_REGEX.match(musicPath)) ? EXT_REGEX.replace(musicPath, '.${FlxRhythmConductorConstants.META_FILE_EXT}') : musicPath
			+ '.${FlxRhythmConductorConstants.META_FILE_EXT}';
}
