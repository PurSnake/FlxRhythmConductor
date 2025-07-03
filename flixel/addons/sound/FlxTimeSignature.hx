package flixel.addons.sound;

#if FLOATED_TIME_SIGNATURE
typedef FlxTimeSignature = Float;
/*
abstract FlxTimeSignature(Float) from Float from Int to Float
{
	public inline function new(Value:Float = 0)
	{
		this = Value;
	}

	@:to
	public inline function toInt():Int
	{
		return Math.floor(this);
	}
}
*/
#else
abstract FlxTimeSignature(Int) from Int to Int to Float
{
	public inline function new(Value:Int = 0)
	{
		this = Value;
	}

	@:from
	public inline static function fromFloat(i:Float):FlxTimeSignature
	{
		return new FlxTimeSignature(Math.floor(i));
	}
}
#end