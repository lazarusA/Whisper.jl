module Whisper
    using DataDeps
    include("LibWhisper.jl")
    using Whisper.LibWhisper
    using SampledSignals
    using Suppressor

    include("models.jl")
    include("transcribe.jl")

    function __init__()
        ENV["DATADEPS_ALWAYS_ACCEPT"]="true"
        register_datadeps()
    end

end
