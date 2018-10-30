"""
    resolve_lxcom(lxc, lxdefs; inmath)

Take a `LxCom` object `lxc` and try to resolve it. Provided a definition
exists etc, the definition is plugged in then sent forward to be re-parsed
(in case further latex is present).
"""
function resolve_lxcom(lxc::LxCom, lxdefs::Vector{LxDef}; inmath=false)

    i = findfirst("{", lxc.ss)
    name = isnothing(i) ? lxc.ss : subs(lxc.ss, 1:(first(i)-1))
    # sort special commands where the input depends on context
    haskey(JD_REF_COMS, name) && return JD_REF_COMS[name](lxc)

    # retrieve the definition attached to the command
    lxdef = getdef(lxc)
    # lxdef = nothing means we're inmath & not found -> let KaTeX deal with it
    isnothing(lxdef) && return lxc.ss
    # lxdef = something -> maybe inmath + found; retrieve & apply
    partial = lxdef
    for (argnum, β) ∈ enumerate(lxc.braces)
        # space sensitive "unsafe" one
        # e.g. blah/!#1 --> blah/blah but note that
        # \command!#1 --> \commandblah and \commandblah would not be found
        partial = replace(partial, "!#$argnum" => content(β))
        # non-space sensitive "safe" one
        # e.g. blah/#1 --> blah/ blah but note that
        # \command#1 --> \command blah and no error.
        partial = replace(partial, "#$argnum" => " " * content(β))
    end
    partial = ifelse(inmath, mathenv(partial), partial) * EOS

    # reprocess (we don't care about jd_vars=nothing)
    plug, _ = convert_md(partial, lxdefs, isrecursive=true,
                         isconfig=false, has_mddefs=false)
    return plug
end