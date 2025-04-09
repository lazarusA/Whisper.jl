using Whisper, FileIO
using LibSndFile

_sdata = load(joinpath(@__DIR__, "female-voice-whispering-wake-up-66605.ogg"))

model_att = joinpath(@__DIR__, "models/ggml-base.en.bin")

result = transcribe(model_att, _sdata)