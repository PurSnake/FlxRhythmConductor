package rhythm.conductor;

#if FLOATED_TIME_SIGNATURE
typedef TimeSignature = Float;
#else
abstract TimeSignature(Int) from Int to Int to Float {
	@:from public static inline function fromFloat(f:Float):TimeSignature {
		return Math.floor(f);
	}
}
#end
