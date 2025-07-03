package flixel.addons.sound;

import flixel.FlxG;
import flixel.addons.sound.FlxRhythmConductorConstants as Constants;
import flixel.addons.sound.FlxRhythmConductorUtil;
import flixel.addons.sound.FlxTimeSignature;
import flixel.addons.sound.MusicTimeChangeEvent;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.util.FlxSort;
import flixel.util.FlxSignal;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import haxe.Log;

using flixel.addons.sound.FlxRhythmConductorUtil;

@:nullSafety
class FlxRhythmConductor implements IFlxDestroyable
{
	public static var instance(get, never):FlxRhythmConductor;

	public var target(get, set):Null<FlxSound>;

	public var timeChanges:Array<MusicTimeChangeEvent> = [];
	public var currentTimeChange(default, null):Null<MusicTimeChangeEvent>;

	public var musicPosition(default, null):Float = 0;
	public var frameMusicPosition(default, null):Float = 0;

	public var musicLength(get, never):Float;

	public var currentBpm(get, never):Float;
	public var startBpm(get, never):Float;

	public var currentMeasure(default, null):Int = 0;
	public var currentMeasureTime(default, null):Float = 0;

	public var currentBeat(default, null):Int = 0;
	public var currentBeatTime(default, null):Float = 0;

	public var currentStep(default, null):Int = 0;
	public var currentStepTime(default, null):Float = 0;

	public static var measureHit(default, null):FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
	public var onMeasureHit(default, null):FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();

	public static var beatHit(default, null):FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
	public var onBeatHit(default, null):FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();

	public static var stepHit(default, null):FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
	public var onStepHit(default, null):FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();

	public static var bpmChange(default, null):FlxTypedSignal<Float->Void> = new FlxTypedSignal<Float->Void> ();
	public var onBpmChange(default, null):FlxTypedSignal<Float->Void> = new FlxTypedSignal<Float->Void> ();

	static function dispatchMeasureHit(measure:Int):Void
	{
		FlxRhythmConductor.measureHit.dispatch(measure);
	}

	static function dispatchBeatHit(beat:Int):Void
	{
		FlxRhythmConductor.beatHit.dispatch(beat);
	}

	static function dispatchStepHit(step:Int):Void
	{
		FlxRhythmConductor.stepHit.dispatch(step);
	}

	static function dispatchBpmChange(bpm:Float):Void
	{
		FlxRhythmConductor.bpmChange.dispatch(bpm);
	}

	static function setupSingleton(input:FlxRhythmConductor):Void
	{
		input.onMeasureHit.add(dispatchMeasureHit);

		input.onBeatHit.add(dispatchBeatHit);

		input.onStepHit.add(dispatchStepHit);

		input.onBpmChange.add(dispatchBpmChange);
	}

	static function clearSingleton(input:FlxRhythmConductor):Void
	{
		input.onMeasureHit.remove(dispatchMeasureHit);

		input.onBeatHit.remove(dispatchBeatHit);

		input.onStepHit.remove(dispatchStepHit);

		input.onBpmChange.remove(dispatchBpmChange);
	}

	var overrideBpm:Null<Float> = null;
	@:noCompletion var prevTimestamp:Float = 0;
	@:noCompletion var prevTime:Float = 0;

	@:noCompletion var _updateTarget:Null<FlxSound>;

	static var _instance:Null<FlxRhythmConductor> = null;

	var _target:Null<FlxSound> = null;

	/**
	 * The Contructor.
	 */
	public function new()
	{
		#if debug
		connectWatch();
		#end
	}

	public function connectWatch()
	{
		#if debug
		FlxG.watch.add(this, 'musicPosition', 'musicPosition');
		FlxG.watch.add(this, 'frameMusicPosition', 'frameMusicPosition');
		FlxG.watch.add(this, 'currentBpm', 'currentBpm');

		FlxG.watch.add(this, 'currentStepTime', 'currentStepTime');
		FlxG.watch.add(this, 'currentBeatTime', 'currentBeatTime');
		FlxG.watch.add(this, 'currentMeasureTime', 'currentMeasureTime');

		FlxG.watch.add(this, 'currentStep', 'currentStep');
		FlxG.watch.add(this, 'currentBeat', 'currentBeat');
		FlxG.watch.add(this, 'currentMeasure', 'currentMeasure');

		FlxG.watch.add(this, 'timeSignatureNumerator', 'timeSignatureNumerator');
		FlxG.watch.add(this, 'timeSignatureDenominator', 'timeSignatureDenominator');

		FlxG.signals.postUpdate.add(quickWatchStuff);
		#end
	}

	public function removeWatch()
	{
		#if debug
		@:nullSafety(Off)
		{
			FlxG.watch.remove(this, 'musicPosition');
			FlxG.watch.remove(this, 'frameMusicPosition');
			FlxG.watch.remove(this, 'currentBpm');

			FlxG.watch.remove(this, 'currentStepTime');
			FlxG.watch.remove(this, 'currentBeatTime');
			FlxG.watch.remove(this, 'currentMeasureTime');

			FlxG.watch.remove(this, 'currentStep');
			FlxG.watch.remove(this, 'currentBeat');
			FlxG.watch.remove(this, 'currentMeasure');

			FlxG.watch.remove(this, 'timeSignatureNumerator');
			FlxG.watch.remove(this, 'timeSignatureDenominator');

			FlxG.signals.postUpdate.remove(quickWatchStuff);
		}
		#end
	}

	public function destroy():Void
	{
		timeChanges = [];

		#if debug
		removeWatch();
		#end
	}

	public static function reset():Void
	{
		if (FlxRhythmConductor._instance != null)
			FlxRhythmConductor._instance.destroy();

		set_instance(new FlxRhythmConductor());
	}

	public var measureLengthMs(get, never):Float;

	public var beatLengthMs(get, never):Float;

	public var stepLengthMs(get, never):Float;

	public var beatsPerMeasure(get, never):Float;

	public var stepsPerMeasure(get, never):Int;

	public var timeSignatureNumerator(get, never):FlxTimeSignature;

	public var timeSignatureDenominator(get, never):FlxTimeSignature;

	public function update(?musicPos:Float) // TODO: Avoid constantly using iterations
	{
		_updateTarget = target;

		var oldMeasure:Float = this.currentMeasure;
		var oldBeat:Float = this.currentBeat;
		var oldStep:Float = this.currentStep;
		var oldBpm:Float = this.currentBpm;

		var frameMusicPos:Float = frameMusicPosition + FlxG.elapsed * Constants.MS_PER_SECS;
		if (_updateTarget == null && musicPos == null)
		{
			musicPosition += FlxG.elapsed * Constants.MS_PER_SECS;
			frameMusicPosition += FlxG.elapsed * Constants.MS_PER_SECS;
		}
		else
		{
			var musicPosValue:Float = musicPos ?? _updateTarget?.time ?? 0;

			if (_updateTarget != null && !_updateTarget.playing)
				frameMusicPos = frameMusicPosition;

			if (_updateTarget != null && _updateTarget.playing)
			{
				musicPosition = musicPosValue.clamp(0, musicLength);
				frameMusicPosition = frameMusicPos.clamp(0, musicLength);
			}
			else
			{
				musicPosition = musicPosValue;
				frameMusicPosition = frameMusicPos;
			}
		}

		currentTimeChange = timeChanges[0];
		if (musicPosition > 0.0)
		{
			for (i in 0...timeChanges.length)
			{
				if (this.musicPosition >= timeChanges[i].time)
					currentTimeChange = timeChanges[i];

				if (this.musicPosition < timeChanges[i].time)
					break;
			}
		}

		if (_updateTarget != null && overrideBpm == null && currentTimeChange == null)
			trace("[WARNING] Unable to obtain timeChange, cancelling musicPos update.");
		else
			/* if (musicPosition > 0.0) */ updateValues();

		if (currentBpm != oldBpm)
			this.onBpmChange.dispatch(currentBpm);

		if (currentStep != oldStep)
			this.onStepHit.dispatch(currentStep);

		if (currentBeat != oldBeat)
			this.onBeatHit.dispatch(currentBeat);

		if (currentMeasure != oldMeasure)
			this.onMeasureHit.dispatch(currentMeasure);

		// only update the timestamp if songPosition actually changed
		// which it doesn't do every frame!
		if (musicPosition != prevTime)
		{
			// Update the timestamp for use in-between frames.
			frameMusicPosition = prevTime = musicPosition;
			prevTimestamp = Std.int(haxe.Timer.stamp() * Constants.MS_PER_SECS);
		}
	}

	public function getCurrentTimeChangeBPMAccurate(musicPos:Float):Float
	{
		if (currentTimeChange == null)
			return Constants.BPM;
		if (currentTimeChange.duration > 0 && musicPos <= currentTimeChange.endTime)
		{
			final prevTimeChange = timeChanges[timeChanges.indexOf(currentTimeChange) - 1];

			if (prevTimeChange == null)
				return currentTimeChange.bpm;

			var neededBpm = FlxMath.lerp(prevTimeChange.bpm, currentTimeChange.bpm, currentTimeChange.caltEase(musicPos));
			// trace(currentTimeChange.caltEase(musicPos));
			if (musicPos + FlxG.elapsed * Constants.MS_PER_SECS >= currentTimeChange.endTime)
				neededBpm = currentTimeChange.bpm;

			return neededBpm;
		}
		return currentTimeChange.bpm;
	}

	public function setupTimeChanges(songTimeChanges:Array<MusicTimeChangeEvent>):Void
	{
		if (songTimeChanges.length > 0)
		{
			timeChanges = songTimeChanges.copy();
			MusicTimeChangeEvent.sortTimeChanges(timeChanges);
		}
		else
		{
			timeChanges = [];
		}

		update(musicPosition);
	}

	static function quickWatchStuff()
	{
		FlxG.watch.addQuick("ct:time", FlxRhythmConductor.instance.currentTimeChange?.time);
		FlxG.watch.addQuick("ct:dur", FlxRhythmConductor.instance.currentTimeChange?.duration);
		FlxG.watch.addQuick("ct:etime", FlxRhythmConductor.instance.currentTimeChange?.endTime);
		// FlxG.watch.addQuick("ct:ease", FlxRhythmConductor.instance.currentTimeChange?.ease);
	}

	function updateValues()
	{
		// currentStepTime = currentTimeChange != null ? getCumulativeSteps(musicPosition) : FlxMath.roundDecimal((musicPosition / stepLengthMs), 4);
		currentStepTime = getCumulativeSteps(musicPosition);
		currentBeatTime = currentStepTime / Constants.STEPS_PER_BEAT;
		currentMeasureTime = getCumulativeMeasures(musicPosition);

		currentStep = Math.ceil(currentStepTime);
		currentBeat = Math.ceil(currentBeatTime);
		currentMeasure = Math.ceil(currentMeasureTime);
	}

	public function getCumulativeSteps(time:Float):Float
	{
		if (timeChanges.length == 0)
			return (time / stepLengthMs); // FlxMath.roundDecimal((time / stepLengthMs), 4);

		var totalSteps:Float = 0;
		var lastEventEndTime:Float = 0;
		var lastBpm:Float = startBpm;
		var timePassed:Float = 0;

		for (i in 0...timeChanges.length)
		{
			var event = timeChanges[i];
			var nextEvent = (i < timeChanges.length - 1) ? timeChanges[i + 1] : null;
			var eventEndTime = event.time;

			if (lastEventEndTime < event.time && time > lastEventEndTime)
			{
				var segmentStart = lastEventEndTime;
				var segmentEnd = Math.min(event.time, time);
				var segmentDuration = segmentEnd - segmentStart;

				if (segmentDuration > 0)
				{
					totalSteps += segmentDuration * lastBpm.getStepsPerMs();
					timePassed += segmentDuration;
				}
			}

			if (time <= event.time)
				break;

			if (event.duration > 0)
			{
				eventEndTime += event.duration;
				var interpStart = Math.max(event.time, lastEventEndTime);
				var interpEnd = Math.min(eventEndTime, time);
				var interpDuration = interpEnd - interpStart;

				if (interpDuration > 0)
				{
					var prevBpm = (i == 0) ? startBpm : timeChanges[i - 1].bpm;
					var progress = (interpStart - event.time) / event.duration;
					var progressEnd = (interpEnd - event.time) / event.duration;

					var steps:Float = 0.0;
					// var stepsPerPart:Int = 100;
					var stepsPerPart:Int = Math.floor(interpDuration / 10);
					var partDuration:Float = interpDuration / stepsPerPart;

					for (j in 0...stepsPerPart)
					{
						var partStart = interpStart + j * partDuration;
						// var partProgress = (partStart - event.time) / event.duration;
						var currentBpm = FlxMath.lerp(prevBpm, event.bpm, event.caltEase(partStart));
						steps += partDuration * currentBpm.getStepsPerMs();
					}

					totalSteps += steps;
					timePassed += interpDuration;
				}
				lastBpm = event.bpm;
				lastEventEndTime = eventEndTime;
			}
			else
			{
				lastBpm = event.bpm;
				lastEventEndTime = event.time;
			}

			if (time > eventEndTime && (nextEvent == null || time < nextEvent.time))
			{
				var segmentStart = eventEndTime;
				var segmentEnd = (nextEvent != null ? Math.min(nextEvent.time, time) : time);
				var segmentDuration = segmentEnd - segmentStart;

				if (segmentDuration > 0)
				{
					totalSteps += segmentDuration * lastBpm.getStepsPerMs();
					timePassed += segmentDuration;
				}
				lastEventEndTime = segmentEnd;
			}

			if (time <= lastEventEndTime)
				break;
		}

		if (time > lastEventEndTime)
		{
			var segmentDuration = time - lastEventEndTime;
			totalSteps += segmentDuration * lastBpm.getStepsPerMs();
		}

		return totalSteps;
	}

	public function getCumulativeMeasures(time:Float):Float
	{
		if (timeChanges.length == 0)
			return currentBeatTime / timeSignatureNumerator;

		var totalMeasures:Float = 0;
		var lastEventEndTime:Float = 0;
		var lastBpm:Float = startBpm;
		var lastTimeSignatureNum:FlxTimeSignature = Constants.TIME_SIGNATURE_NUM;
		var lastTimeSignatureDen:FlxTimeSignature = Constants.TIME_SIGNATURE_DEN;
		var timePassed:Float = 0;

		for (i in 0...timeChanges.length)
		{
			var event = timeChanges[i];
			var nextEvent = (i < timeChanges.length - 1) ? timeChanges[i + 1] : null;
			var eventEndTime = event.time;

			if (lastEventEndTime < event.time && time > lastEventEndTime)
			{
				var segmentStart = lastEventEndTime;
				var segmentEnd = Math.min(event.time, time);
				var segmentDuration = segmentEnd - segmentStart;

				if (segmentDuration > 0)
				{
					var measureLengthMs = lastBpm.getMeasureLengthMs(lastTimeSignatureNum, lastTimeSignatureDen);
					totalMeasures += segmentDuration / measureLengthMs;
					timePassed += segmentDuration;
				}
			}

			if (time <= event.time)
				break;

			lastTimeSignatureNum = event.timeSignatureNum;
			lastTimeSignatureDen = event.timeSignatureDen;

			if (event.duration > 0)
			{
				eventEndTime += event.duration;
				var interpStart = Math.max(event.time, lastEventEndTime);
				var interpEnd = Math.min(eventEndTime, time);
				var interpDuration = interpEnd - interpStart;

				if (interpDuration > 0)
				{
					var prevBpm = (i == 0) ? startBpm : timeChanges[i - 1].bpm;
					// var stepsPerPart = 100;
					var stepsPerPart:Int = Math.floor(interpDuration / 10);
					var partDuration = interpDuration / stepsPerPart;

					for (j in 0...stepsPerPart)
					{
						var partStart = interpStart + j * partDuration;
						// var partProgress = (partStart - event.time) / event.duration;
						var currentBpm = FlxMath.lerp(prevBpm, event.bpm, event.caltEase(partStart));

						var measureLengthMs = currentBpm.getMeasureLengthMs(lastTimeSignatureNum, lastTimeSignatureDen);
						totalMeasures += partDuration / measureLengthMs;
					}
					timePassed += interpDuration;
				}
				lastBpm = event.bpm;
				lastEventEndTime = eventEndTime;
			}
			else
			{
				lastBpm = event.bpm;
				lastEventEndTime = event.time;
			}

			if (time > lastEventEndTime && (nextEvent == null || time < nextEvent.time))
			{
				var segmentStart = lastEventEndTime;
				var segmentEnd = (nextEvent != null ? Math.min(nextEvent.time, time) : time);
				var segmentDuration = segmentEnd - segmentStart;

				if (segmentDuration > 0)
				{
					var measureLengthMs = lastBpm.getMeasureLengthMs(lastTimeSignatureNum, lastTimeSignatureDen);
					totalMeasures += segmentDuration / measureLengthMs;
					timePassed += segmentDuration;
				}
				lastEventEndTime = segmentEnd;
			}

			if (time <= lastEventEndTime)
				break;
		}

		if (time > lastEventEndTime)
		{
			var segmentDuration = time - lastEventEndTime;
			var measureLengthMs = lastBpm.getMeasureLengthMs(lastTimeSignatureNum, lastTimeSignatureDen);
			totalMeasures += segmentDuration / measureLengthMs;
		}

		return totalMeasures;
	}

	inline function get_musicLength():Float
	{
		return target?.length ?? Constants.MS_PER_SECS; // 1000 ms
	}

	static function get_instance():FlxRhythmConductor
	{
		if (FlxRhythmConductor._instance == null)
			set_instance(new FlxRhythmConductor());

		if (FlxRhythmConductor._instance == null)
			throw "Could not initialize FlxRhythmConductor instance!";

		return FlxRhythmConductor._instance;
	}

	static function set_instance(newInstance:FlxRhythmConductor):FlxRhythmConductor
	{
		if (FlxRhythmConductor._instance != null)
			clearSingleton(FlxRhythmConductor._instance);

		FlxRhythmConductor._instance = newInstance;

		if (FlxRhythmConductor._instance != null)
			setupSingleton(FlxRhythmConductor._instance);

		return FlxRhythmConductor._instance;
	}

	function get_target():Null<FlxSound>
	{
		return _target ?? FlxG.sound?.music;
	}

	inline function set_target(newTarget:Null<FlxSound>):Null<FlxSound>
	{
		return _target = newTarget;
	}

	function get_measureLengthMs():Float
	{
		return currentBpm.getMeasureLengthMs(timeSignatureNumerator, timeSignatureDenominator);
	}

	function get_beatLengthMs():Float
	{
		return currentBpm.getBeatLengthMs();
	}

	inline function get_stepLengthMs():Float
	{
		return currentBpm.getStepLengthMs();
	}

	function get_beatsPerMeasure():Float
	{
		return FlxRhythmConductorUtil.getBeatsPerMeasure(timeSignatureNumerator, timeSignatureDenominator);
	}

	function get_stepsPerMeasure():Int
	{
		return FlxRhythmConductorUtil.getStepsPerMeasure(timeSignatureNumerator, timeSignatureDenominator);
	}

	inline function get_timeSignatureNumerator():FlxTimeSignature
	{
		return currentTimeChange?.timeSignatureNum ?? Constants.TIME_SIGNATURE_NUM;
	}

	inline function get_timeSignatureDenominator():FlxTimeSignature
	{
		return currentTimeChange?.timeSignatureDen ?? Constants.TIME_SIGNATURE_DEN;
	}

	function get_currentBpm():Float
	{
		if (overrideBpm != null)
			return overrideBpm;

		return getCurrentTimeChangeBPMAccurate(musicPosition);
	}

	function get_startBpm():Float
	{
		if (overrideBpm != null)
			return overrideBpm;

		return timeChanges[0]?.bpm ?? Constants.BPM;
	}
}
