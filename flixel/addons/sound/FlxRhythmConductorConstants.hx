package flixel.addons.sound;

import flixel.addons.sound.FlxTimeSignature;

@:nullSafety
class FlxRhythmConductorConstants
{
	public static inline final MS_PER_SECS:Int = 1000;
	public static inline final SECS_PER_MIN:Int = 60;
	public static inline final MS_PER_MIN:Int = MS_PER_SECS * SECS_PER_MIN;

	public static inline final BPM:Float = 100.0;

	public static inline final TIME_SIGNATURE_NUM:FlxTimeSignature = 4;
	public static inline final TIME_SIGNATURE_DEN:FlxTimeSignature = 4;

	public static inline final STEPS_PER_BEAT:Int = 4;
	public static inline final BEATS_PER_MEASURE:Int = 4;
	public static inline final STEPS_PER_MEASURE:Int = STEPS_PER_BEAT * BEATS_PER_MEASURE;

	// Will be used as 'path/to/music.${FlxRhythmConductorConstants.META_FILE_EXT}'
	public static var META_FILE_EXT:String = "musicMeta";
}