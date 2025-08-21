package rhythm.conductor;

import haxe.Json;
import rhythm.conductor.MusicTimeChangeEvent.MusicTimeChangeData;
import haxe.PosInfos;

class Util {
	public static inline function clamp(value:Float, min:Float, max:Float):Float {
		return min > value ? min : max < value ? max : value;
	}

	public static inline function lerp(a:Float, b:Float, ratio:Float):Float {
		return a + ratio * (b - a);
	}

	public static inline function getStepsPerMs(bpm:Float):Float {
		return getBeatPerMs(bpm) * Constants.STEPS_PER_BEAT;
	}

	public static inline function getBeatPerMs(bpm:Float):Float {
		return bpm / Constants.MS_PER_MIN;
	}

	public static inline function getStepsPerMeasure(timeSignNum:TimeSignature, timeSignDec:TimeSignature):Int {
		return Math.floor(getTimeSignatureFactor(timeSignNum, timeSignDec) * Constants.STEPS_PER_BEAT * Constants.STEPS_PER_BEAT);
	}

	public static inline function getBeatsPerMeasure(timeSignNum:TimeSignature, timeSignDec:TimeSignature):Float {
		return getStepsPerMeasure(timeSignNum, timeSignDec) / Constants.STEPS_PER_BEAT;
	}

	public static inline function getStepLengthMs(bpm:Float):Float {
		return getBeatLengthMs(bpm) / Constants.STEPS_PER_BEAT;
	}

	public static inline function getBeatLengthMs(bpm:Float):Float {
		return Constants.MS_PER_MIN / bpm;
	}

	public static inline function getMeasureLengthMs(bpm:Float, timeSignNum:TimeSignature, timeSignDen:TimeSignature):Float {
		return getBeatLengthMs(bpm) * getTimeSignatureFactor(timeSignNum, timeSignDen) * Constants.BEATS_PER_MEASURE;
	}

	public static inline function getTimeSignatureFactor(timeSignNum:TimeSignature, timeSignDen:TimeSignature):Float {
		return timeSignNum / timeSignDen;
	}

	public static dynamic function displayWarning(message:Dynamic, ?infos:PosInfos) {
		#if flixel
		flixel.FlxG.log.warn(message);
		#else
		haxe.Log.trace('[WARNING] $message', infos);
		#end
	}

	public static dynamic function displayError(message:Dynamic, ?infos:PosInfos) {
		#if flixel
		flixel.FlxG.log.error(message);
		#else
		haxe.Log.trace('[ERROR] $message', infos);
		#end
	}

	public static dynamic function getTimeDelta():Float {
		#if flixel
		return flixel.FlxG.elapsed;
		#elseif heaps
		return hxd.Timer.elapsedTime;
		#end
	}

	public static inline function loadMetaFromFilePath(rhythmConductor:RhythmConductor, musicPath:String) {
		final arrayOfChanges:Array<MusicTimeChangeEvent> = getTimeChangesFromFile(musicPath);
		loadMeta(rhythmConductor, arrayOfChanges);
	}

	public static inline function loadMeta(rhythmConductor:RhythmConductor, arrayOfChanges:Array<MusicTimeChangeEvent>) {
		rhythmConductor.setupTimeChanges(arrayOfChanges);
	}

	public static function getTimeChangesFromFile(path:String):Array<MusicTimeChangeEvent> {
		final fileMetaPath:String = getMusicMetaPath(path);
		#if openfl
		if (openfl.Assets.exists(fileMetaPath, TEXT))
		#elseif heaps
		if (hxd.Res.loader.exists(fileMetaPath))
		#else
		if (false)
		#end
		{
			try {
				#if openfl
				final parsedData:Null<Array<MusicTimeChangeData>> = Json.parse(openfl.Assets.getText(fileMetaPath));
				#elseif heaps
				final parsedData:Null<Array<MusicTimeChangeData>> = Json.parse(hxd.Res.load(fileMetaPath).toText());
				#else
				final parsedData:Null<Array<MusicTimeChangeData>> = null;
				#end

				final arrayOfChanges:Array<MusicTimeChangeEvent> = parseTimeChanges(parsedData);

				if (arrayOfChanges.length == 0)
					displayWarning('No avalaible timeChanges found in .${Constants.META_FILE_EXT} file for $path');

				return arrayOfChanges;
			} catch (e)
				displayError('Can\t load .${Constants.META_FILE_EXT} file for $path');
		}
		displayError('Can\'t load timeChanges for $path');
		return [];
	}

	public static function parseTimeChanges(data:Null<Array<MusicTimeChangeData>>):Array<MusicTimeChangeEvent> {
		final arrayOfChanges:Array<MusicTimeChangeEvent> = [];
		var lastBPM:Float = Constants.BPM;
		var lastTSN:TimeSignature = Constants.TIME_SIGNATURE_NUM;
		var lastTSD:TimeSignature = Constants.TIME_SIGNATURE_DEN;
		if (data?.length > 0) for (data in data) {
			lastBPM = data.bpm ?? lastBPM;
			lastTSN = data.tsn ?? lastTSN;
			lastTSD = data.tsd ?? lastTSD;
			arrayOfChanges.push(new MusicTimeChangeEvent(data.t, lastBPM, lastTSN, lastTSD, data.d, data.ease));
		}

		return arrayOfChanges;
	}

	private static final EXT_REGEX = new EReg("\\.([^.]+)$", "");

	public static inline function getMusicMetaPath(musicPath:String):String {
		return (EXT_REGEX.match(musicPath)) ? EXT_REGEX.replace(musicPath, '.${Constants.META_FILE_EXT}') : musicPath
			+ '.${Constants.META_FILE_EXT}';
	}
}
