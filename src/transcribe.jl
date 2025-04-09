export transcribe

"""
transcribe(model, data) -> String

Run inference using the Whisper speech-to-text model. The model file is
automatically downloaded from HuggingFace on first use.

- `model`: Whisper model name (such as "base" or "medium.en")
- `data`: `Vector{Float32}` containing 16kHz sampled audio
"""
function transcribe(model, data)
    ctx, wparams = loadWhisperModel(model)
    data = resample_rate_stream(data)
    # Run the heavy computation in a separate thread
    ret = Threads.@spawn begin
        @suppress begin
            Whisper.whisper_full_parallel(ctx, wparams, data, length(data), 1)
        end
    end
    # Wait for the result
    ret = fetch(ret)

    if ret != 0
        error("Error running whisper model: $ret")
    end

    n_segments = whisper_full_n_segments(ctx)

    result = ""
    for i in 0:(n_segments - 1)
        txt = whisper_full_get_segment_text(ctx, i)
        result = result * unsafe_string(txt)
        t0 = whisper_full_get_segment_t0(ctx, i)
        t1 = whisper_full_get_segment_t1(ctx, i)
        @debug "Time for inference: ", t0-t1
    end

    whisper_free(ctx)

    return result
end

"""
    loadWhisperModel(model)

Load the Whisper model from a file path.
"""
function loadWhisperModel(model)
    local ctx, wparams
    @suppress begin
        ctx = Whisper.whisper_init_from_file(model)
        wparams = Whisper.whisper_full_default_params(Whisper.LibWhisper.WHISPER_SAMPLING_GREEDY)
    end
    return ctx, wparams
end

"""
    resample_rate_stream(s)
Resample the audio stream to 16kHz and convert to mono if stereo.

# Arguments    
- `s::SampleBuf{Float32}` The input audio stream to be resampled.

Returns a vector of Float32 containing the resampled audio data.
"""
function resample_rate_stream(s)
    sout = SampleBuf(Float32, 16000, round(Int, length(s)*(16000/samplerate(s))), nchannels(s))
    write(SampleBufSink(sout), SampleBufSource(s)) # Resample
    if nchannels(sout) == 1
        data  = sout.data
    elseif nchannels(sout) == 2
        sd = sout.data
        data = [sd[i,1] + sd[i,2] for i in 1:size(sd)[1]] #convert stereo to mono
    end
    return data
end
