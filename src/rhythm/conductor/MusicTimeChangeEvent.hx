package rhythm.conductor;

import haxe.extern.EitherType;

/**
	Used in rhythm.conductor.Util

	TODO: Beat, Step, Section time variations
**/
typedef MusicTimeChangeData = {
	t:Float,

	?bpm:Float,

	?tsn:TimeSignature,
	?tsd:TimeSignature,

	?d:Float,
	?ease:String,
}

class MusicTimeChangeEvent {
	public var time:Float;
	public var duration:Float;
	public var endTime(get, null):Float;

	/** unused if duration is 0 **/
	public var ease:Float->Float;

	public var bpm:Float;
	public var timeSignatureNum:TimeSignature;
	public var timeSignatureDen:TimeSignature;

	public function new(time:Float = 0.0, newBpm:Float = Constants.BPM, ?timeSignNum:Null<TimeSignature>, ?timeSignDen:Null<TimeSignature>, ?duration:Null<Float>, ?ease:Null<EitherType<String, Float->Float>>) {
		if (duration != null) {
			this.time = Math.max(0, time - duration);
			this.duration = Math.max(0, duration);
		} else {
			this.time = Math.max(0, time);
			this.duration = 0.0;
		}
		this.bpm = Math.max(0, newBpm);
		this.ease = (ease == null ? Easing.linear : ease is String ? getEaseFromName(ease) : ease);
		timeSignatureNum = timeSignNum ?? Constants.TIME_SIGNATURE_NUM;
		timeSignatureDen = timeSignDen ?? Constants.TIME_SIGNATURE_DEN;
	}

	public inline function caltEase(time:Float):Float {
		return Util.clamp((time - this.time) / duration, 0, 1);
	}

	public static function getEaseFromName(ease:String):Float->Float {
		if (Reflect.hasField(Easing, ease))
			return Reflect.field(Easing, ease);

		return Easing.linear;
	}

	public static function sortTimeChanges(timeChangesArr:Array<MusicTimeChangeEvent>, descrease:Bool = false):Array<MusicTimeChangeEvent> {
		final order:Int = descrease ? 1 : -1;
		timeChangesArr.sort((a, b) -> {
			if (a.time < b.time) order;
			else if (a.time > b.time) -order;
			else 0;
		});
		return timeChangesArr;
	}

	inline function get_endTime():Float { // can actually represent this timeChange time
		return time + duration;
	}

	inline function toString():String {
		return 'MusicTimeChangeEvent(time=$time, duration=$duration, bpm=$bpm, timeSignNum=$timeSignatureNum, timeSignDen=$timeSignatureDen)';
	}
}
