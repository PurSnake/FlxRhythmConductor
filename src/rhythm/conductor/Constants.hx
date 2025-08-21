package rhythm.conductor;

class Constants {
	public static inline var MUSIC_POSITION_OFFSET:Float = 0.0;
	
	public static inline var MS_PER_SECS:Int = 1000;
	public static inline var SECS_PER_MIN:Int = 60;
	public static inline var MS_PER_MIN:Int = MS_PER_SECS * SECS_PER_MIN;

	public static inline var BPM:Float = 100.0;

	public static inline var TIME_SIGNATURE_NUM:TimeSignature = 4;
	public static inline var TIME_SIGNATURE_DEN:TimeSignature = 4;

	public static inline var STEPS_PER_BEAT:Int = 4;
	public static inline var BEATS_PER_MEASURE:Int = 4;
	public static inline var STEPS_PER_MEASURE:Int = STEPS_PER_BEAT * BEATS_PER_MEASURE;

	/** Will be used as `path/to/music.${FlxRhythmConductorConstants.META_FILE_EXT}` **/
	public static var META_FILE_EXT:String = 'musicMeta';
}
