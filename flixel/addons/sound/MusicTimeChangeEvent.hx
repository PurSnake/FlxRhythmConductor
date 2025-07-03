package flixel.addons.sound;

import flixel.util.typeLimit.OneOfTwo;
import flixel.addons.sound.FlxRhythmConductorConstants;
import flixel.addons.sound.FlxRhythmConductorUtil;
import flixel.addons.sound.FlxTimeSignature;
import flixel.tweens.FlxEase;
import flixel.util.FlxSort;

// Used in FlxRhythmConductorUtil
typedef MusicTimeChangeData =
{
	var t:Float; // TODO: Beat, Step, Section time variations

	@:optional
	var bpm:Null<Float>;

	@:optional
	var tsn:Null<FlxTimeSignature>;
	@:optional
	var tsd:Null<FlxTimeSignature>;

	@:optional
	var d:Null<Float>;
	@:optional
	var ease:Null<String>;
}

@:nullSafety
class MusicTimeChangeEvent
{
	public var time:Float;
	public var duration:Float;
	@:nullSafety(Off) public var endTime(get, null):Float;

	public var ease:EaseFunction; // unused, if duration = 0
	public var bpm:Float;
	public var timeSignatureNum:FlxTimeSignature;
	public var timeSignatureDen:FlxTimeSignature;

	public function new(time:Float = 0.0, newBpm:Float = FlxRhythmConductorConstants.BPM, ?timeSignNum:Null<FlxTimeSignature>,
			?timeSignDen:Null<FlxTimeSignature>, ?duration:Null<Float>, ?ease:Null<OneOfTwo<String, EaseFunction>>)
	{
		if (duration != null)
		{
			this.time = Math.max(0, time - duration);
			this.duration = Math.max(0, duration);
		}
		else
		{
			this.time = Math.max(0, time);
			this.duration = 0.0;
		}
		this.bpm = Math.max(0, newBpm);
		this.ease = (ease == null ? FlxEase.linear : ease is String ? getEaseFromName(ease) : ease);
		timeSignatureNum = timeSignNum ?? FlxRhythmConductorConstants.TIME_SIGNATURE_NUM;
		timeSignatureDen = timeSignDen ?? FlxRhythmConductorConstants.TIME_SIGNATURE_DEN;
	}

	public inline function caltEase(time:Float):Float
	{
		return FlxRhythmConductorUtil.clamp((time - this.time) / duration, 0, 1);
	}

	public static function getEaseFromName(ease:String):EaseFunction
	{
		if (Reflect.hasField(FlxEase, ease))
			return Reflect.field(FlxEase, ease);

		return FlxEase.linear;
	}

	public static function sortTimeChanges(timeChangesArr:Array<MusicTimeChangeEvent>, descrease:Bool = false):Array<MusicTimeChangeEvent>
	{
		timeChangesArr.sort((a:MusicTimeChangeEvent,
				b:MusicTimeChangeEvent) -> FlxSort.byValues(descrease ? FlxSort.DESCENDING : FlxSort.ASCENDING, a.time, b.time));
		return timeChangesArr;
	}

	inline function get_endTime():Float // can actually represent this timeChange time
		return time + duration;

	inline function toString():String
		return 'MusicTimeChangeEvent(time=$time, duration=$duration, bpm=$bpm, timeSignNum=$timeSignatureNum, timeSignDen=$timeSignatureDen)';
}
